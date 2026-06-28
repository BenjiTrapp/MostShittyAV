when defined(windows):
    import winim/lean
    import winim/com
    import os

    # Import the complete scanner module - we use its scan() method
    import nim_antimalware_sim

    const PROVIDER_GUID = "{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}"
    const PROVIDER_NAME = "MostShittyAVProvider"

    var g_hModule: HMODULE = 0

    ###########################################################################
    # IAmsiStream vtable                                                      #
    # Matches the COM interface defined in amsi.h:                            #
    #   IAmsiStream : IUnknown                                                #
    #     GetAttribute(attribute, dataSize, data, retData) → HRESULT          #
    #     Read(buffer, dataSize, readSize)                 → HRESULT          #
    ###########################################################################
    const
        AMSI_ATTRIBUTE_CONTENT_SIZE    = 2'i32   # returns ULONGLONG with byte count
        AMSI_ATTRIBUTE_CONTENT_ADDRESS = 3'i32   # returns ULONGLONG with buffer ptr

    type
        TAmsiGetAttribute = proc(this: pointer; attribute: int32;
                                  dataSize: ULONG; data: pointer;
                                  retData: ptr ULONG): HRESULT {.stdcall.}
        TAmsiRead         = proc(this: pointer; pbBuffer: pointer;
                                  cbBuffer: ULONG;
                                  pcbActuallyRead: ptr ULONG): HRESULT {.stdcall.}
        TAmsiStreamVtbl   = object
            QueryInterface: pointer          # IUnknown – not called by provider
            AddRef:         pointer
            Release:        pointer
            GetAttribute:   TAmsiGetAttribute
            Read:           TAmsiRead
        TAmsiStream = object
            lpVtbl: ptr TAmsiStreamVtbl

    ###########################################################################
    # IAntimalwareProvider vtable                                             #
    # Matches the COM interface defined in amsi.h:                            #
    #   IAntimalwareProvider : IUnknown                                       #
    #     Scan(stream, result)          → HRESULT                             #
    #     CloseSession(session)         → void                                #
    #     DisplayName(displayName)      → HRESULT                             #
    ###########################################################################
    type
        TPQueryInterface = proc(this: pointer, riid: pointer, ppv: ptr pointer): HRESULT {.stdcall.}
        TPAddRef         = proc(this: pointer): ULONG {.stdcall.}
        TPRelease        = proc(this: pointer): ULONG {.stdcall.}
        # Fixed: removed extra `session` parameter; stream is IAmsiStream*
        TPScan           = proc(this: pointer, stream: pointer, result: ptr UINT): HRESULT {.stdcall.}
        # Fixed: returns void (not HRESULT), session is ULONGLONG (not pointer)
        TPCloseSession   = proc(this: pointer, session: uint64): void {.stdcall.}
        TPDisplayName    = proc(this: pointer, name: ptr BSTR): HRESULT {.stdcall.}

        TAmsiProviderVtbl* = object
            QueryInterface*: TPQueryInterface
            AddRef*:         TPAddRef
            Release*:        TPRelease
            Scan*:           TPScan
            CloseSession*:   TPCloseSession
            DisplayName*:    TPDisplayName

        TAmsiProvider* = object
            lpVtbl*: ptr TAmsiProviderVtbl

    proc QueryInterfaceImpl(this: pointer, riid: pointer, ppv: ptr pointer): HRESULT {.stdcall.} =
        if ppv != nil:
            ppv[] = this
        return S_OK

    proc AddRefImpl(this: pointer): ULONG {.stdcall.} = 1
    proc ReleaseImpl(this: pointer): ULONG {.stdcall.} = 1

    ###########################################################################
    # ScanImpl – reads content via IAmsiStream::GetAttribute                  #
    # Bug fixed: previously cast `request` directly as a raw byte buffer,     #
    # which reads garbage from the COM vtable pointer instead of the actual   #
    # scan content. The correct approach is to call GetAttribute on the       #
    # IAmsiStream interface to retrieve the content address and size.         #
    ###########################################################################
    proc ScanImpl(this: pointer, stream: pointer, pResult: ptr UINT): HRESULT {.stdcall.} =
        if stream == nil or pResult == nil:
            if pResult != nil: pResult[] = 0
            return E_INVALIDARG

        try:
            echo "AMSI Provider: ScanImpl called"

            let amsiStream = cast[ptr TAmsiStream](stream)
            var retData: ULONG = 0

            # Step 1: read content size from IAmsiStream
            var contentSize: uint64 = 0
            var hr = amsiStream.lpVtbl.GetAttribute(
                stream, AMSI_ATTRIBUTE_CONTENT_SIZE,
                sizeof(contentSize).ULONG, addr contentSize, addr retData)
            if hr != S_OK or contentSize == 0:
                echo "AMSI Provider: Empty or unreadable content, marking clean"
                pResult[] = 0  # AMSI_RESULT_CLEAN
                return S_OK

            # Step 2: read content address from IAmsiStream
            var contentAddr: uint64 = 0
            hr = amsiStream.lpVtbl.GetAttribute(
                stream, AMSI_ATTRIBUTE_CONTENT_ADDRESS,
                sizeof(contentAddr).ULONG, addr contentAddr, addr retData)
            if hr != S_OK or contentAddr == 0:
                echo "AMSI Provider: Cannot get content address, marking clean"
                pResult[] = 0  # AMSI_RESULT_CLEAN
                return S_OK

            # Step 3: copy bytes from the AMSI content buffer (cap at 8 KB)
            let scanLen = min(contentSize.int, 8192)
            let contentPtr = cast[ptr UncheckedArray[byte]](contentAddr)
            var content = newSeq[byte](scanLen)
            for i in 0 ..< scanLen:
                content[i] = contentPtr[i]

            echo "AMSI Provider: Scanning ", scanLen, " bytes"

            # Step 4: write to temp file and run the existing file scanner
            let tempPath = getTempDir() / "amsi_scan_" & $getCurrentProcessId() & ".tmp"
            try:
                let f = open(tempPath, fmWrite)
                discard f.writeBytes(content, 0, content.len)
                f.close()

                var provider = LoggingAntimalwareProvider(name: "MostShittyAV AMSI Provider")
                let isClean = provider.scan(tempPath)

                removeFile(tempPath)

                if isClean:
                    pResult[] = 0       # AMSI_RESULT_CLEAN
                    echo "AMSI Provider: Result = CLEAN"
                else:
                    pResult[] = 32768   # AMSI_RESULT_DETECTED
                    echo "AMSI Provider: Result = DETECTED"

                return S_OK

            except:
                if fileExists(tempPath):
                    try: removeFile(tempPath)
                    except: discard
                raise

        except Exception as e:
            echo "AMSI Provider: Exception in ScanImpl: ", e.msg
            if pResult != nil: pResult[] = 0
            return E_FAIL

    # Fixed: returns void (not HRESULT), session is uint64 (not pointer)
    proc CloseSessionImpl(this: pointer, session: uint64): void {.stdcall.} =
        discard  # No persistent session state in this provider

    proc DisplayNameImpl(this: pointer, name: ptr BSTR): HRESULT {.stdcall.} =
        if name != nil:
            name[] = SysAllocString("MostShittyAV Nim Demo Provider (Wrapper)")
        return S_OK

    var DemoVtbl*:    TAmsiProviderVtbl
    var DemoProvider*: TAmsiProvider

    DemoVtbl = TAmsiProviderVtbl(
        QueryInterface: QueryInterfaceImpl,
        AddRef:         AddRefImpl,
        Release:        ReleaseImpl,
        Scan:           ScanImpl,
        CloseSession:   CloseSessionImpl,
        DisplayName:    DisplayNameImpl
    )

    DemoProvider = TAmsiProvider(lpVtbl: addr DemoVtbl)

    proc getOurModuleHandle(): HMODULE =
        var hm: HMODULE
        let funcPtr = cast[pointer](getOurModuleHandle)
        let funcAddr = cast[LPCSTR](funcPtr)
        if GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS or
                               GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                               funcAddr, addr hm) != 0:
            return hm
        return 0

    proc DllGetClassObject(rclsid: pointer, riid: pointer, ppv: ptr pointer): HRESULT {.exportc, stdcall, dynlib.} =
        if ppv == nil:
            return E_POINTER
        ppv[] = cast[pointer](addr DemoProvider)
        echo "DllGetClassObject (wrapper) called"
        return S_OK

    proc DllCanUnloadNow(): HRESULT {.exportc, stdcall, dynlib.} =
        return S_FALSE

    proc DllRegisterServer(): HRESULT {.exportc, stdcall, dynlib.} =
        try:
            var hKey: HKEY
            var disposition: DWORD

            let clsidPath = "SOFTWARE\\Classes\\CLSID\\" & PROVIDER_GUID
            var regResult = RegCreateKeyExA(HKEY_LOCAL_MACHINE, clsidPath, 0, nil,
                                            REG_OPTION_NON_VOLATILE, KEY_WRITE, nil,
                                            addr hKey, addr disposition)
            if regResult != ERROR_SUCCESS:
                echo "DllRegisterServer: Failed to create CLSID key: ", regResult
                return HRESULT(ERROR_ACCESS_DENIED)

            let providerNameStr = "MostShittyAV AMSI Provider"
            discard RegSetValueExA(hKey, nil, 0, REG_SZ,
                                   cast[LPBYTE](unsafeAddr providerNameStr[0]),
                                   DWORD(providerNameStr.len + 1))
            discard RegCloseKey(hKey)

            let inprocPath = clsidPath & "\\InprocServer32"
            regResult = RegCreateKeyExA(HKEY_LOCAL_MACHINE, inprocPath, 0, nil,
                                        REG_OPTION_NON_VOLATILE, KEY_WRITE, nil,
                                        addr hKey, addr disposition)
            if regResult != ERROR_SUCCESS:
                echo "DllRegisterServer: Failed to create InprocServer32 key: ", regResult
                return HRESULT(ERROR_ACCESS_DENIED)

            if g_hModule == 0:
                g_hModule = getOurModuleHandle()

            var dllPath: array[MAX_PATH, char]
            let pathLen = GetModuleFileNameA(g_hModule, cast[LPSTR](addr dllPath[0]), MAX_PATH)
            if pathLen == 0 or pathLen >= MAX_PATH:
                echo "DllRegisterServer: Failed to get DLL path: ", GetLastError()
                discard RegCloseKey(hKey)
                return HRESULT(ERROR_BAD_PATHNAME)

            discard RegSetValueExA(hKey, nil, 0, REG_SZ,
                                   cast[LPBYTE](addr dllPath[0]),
                                   DWORD(pathLen + 1))
            echo "DllRegisterServer: DLL Path = ", cast[cstring](addr dllPath[0])

            let threadingModel = "Both"
            discard RegSetValueExA(hKey, "ThreadingModel", 0, REG_SZ,
                                   cast[LPBYTE](unsafeAddr threadingModel[0]),
                                   DWORD(threadingModel.len + 1))
            discard RegCloseKey(hKey)

            let amsiPath = "SOFTWARE\\Microsoft\\AMSI\\Providers\\" & PROVIDER_GUID
            regResult = RegCreateKeyExA(HKEY_LOCAL_MACHINE, amsiPath, 0, nil,
                                        REG_OPTION_NON_VOLATILE, KEY_WRITE, nil,
                                        addr hKey, addr disposition)
            if regResult != ERROR_SUCCESS:
                echo "DllRegisterServer: Failed to create AMSI Provider key: ", regResult
                return HRESULT(ERROR_ACCESS_DENIED)

            let providerNameCopy = PROVIDER_NAME
            discard RegSetValueExA(hKey, nil, 0, REG_SZ,
                                   cast[LPBYTE](unsafeAddr providerNameCopy[0]),
                                   DWORD(providerNameCopy.len + 1))
            discard RegCloseKey(hKey)

            echo "DllRegisterServer: Successfully registered as AMSI Provider"
            echo "  CLSID: ", PROVIDER_GUID
            echo "  Provider: ", PROVIDER_NAME
            return S_OK

        except OSError as e:
            echo "DllRegisterServer OSError: ", e.msg
            return HRESULT(ERROR_ACCESS_DENIED)
        except:
            echo "DllRegisterServer: Unexpected error"
            return E_FAIL

    proc DllUnregisterServer(): HRESULT {.exportc, stdcall, dynlib.} =
        try:
            let amsiPath = "SOFTWARE\\Microsoft\\AMSI\\Providers\\" & PROVIDER_GUID
            discard RegDeleteKeyA(HKEY_LOCAL_MACHINE, amsiPath)
            echo "DllUnregisterServer: Removed AMSI Provider key"

            let inprocPath = "SOFTWARE\\Classes\\CLSID\\" & PROVIDER_GUID & "\\InprocServer32"
            discard RegDeleteKeyA(HKEY_LOCAL_MACHINE, inprocPath)

            let clsidPath = "SOFTWARE\\Classes\\CLSID\\" & PROVIDER_GUID
            discard RegDeleteKeyA(HKEY_LOCAL_MACHINE, clsidPath)
            echo "DllUnregisterServer: Removed CLSID registration"

            return S_OK
        except OSError as e:
            echo "DllUnregisterServer OSError: ", e.msg
            return HRESULT(ERROR_ACCESS_DENIED)
        except:
            echo "DllUnregisterServer: Unexpected error"
            return E_FAIL

    proc GetDemoProviderPtr(): pointer {.exportc.} =
        return addr DemoProvider

else:
    echo "This DLL wrapper file is intended for Windows."
