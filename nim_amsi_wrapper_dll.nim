when defined(windows):
    import winim/lean
    import winim/com
    import os

    # Import the complete scanner module - we use its scan() method
    import nim_antimalware_sim

    const PROVIDER_GUID = "{2E5D8A62-77F9-4F7B-A90B-1C8F6E9D4C3A}"
    const PROVIDER_NAME = "MostShittyAVProvider"

    var g_hModule: HMODULE = 0
    var g_refCount: int32 = 0

    # AMSI types
    type
        HAMSICONTEXT* = pointer
        HAMSISESSION* = pointer

    type
        TPQueryInterface = proc(this: pointer, riid: pointer, ppv: ptr pointer): HRESULT {.stdcall.}
        TPAddRef = proc(this: pointer): ULONG {.stdcall.}
        TPRelease = proc(this: pointer): ULONG {.stdcall.}
        # CORRECT AMSI Scan signature with buffer and length
        TPScan = proc(this: pointer, session: HAMSISESSION, buffer: pointer, length: ULONG, 
                      contentName: LPCWSTR, session2: HAMSISESSION, result: ptr UINT): HRESULT {.stdcall.}
        TPCloseSession = proc(this: pointer, session: HAMSISESSION): HRESULT {.stdcall.}
        TPDisplayName = proc(this: pointer, name: ptr BSTR): HRESULT {.stdcall.}

        TAmsiProviderVtbl* = object
            QueryInterface*: TPQueryInterface
            AddRef*: TPAddRef
            Release*: TPRelease
            Scan*: TPScan
            CloseSession*: TPCloseSession
            DisplayName*: TPDisplayName

        TAmsiProvider* = object
            lpVtbl*: ptr TAmsiProviderVtbl

        # IClassFactory interface
        TPCreateInstance = proc(this: pointer, pUnkOuter: pointer, riid: pointer, ppv: ptr pointer): HRESULT {.stdcall.}
        TPLockServer = proc(this: pointer, fLock: BOOL): HRESULT {.stdcall.}

        TClassFactoryVtbl* = object
            QueryInterface*: TPQueryInterface
            AddRef*: TPAddRef
            Release*: TPRelease
            CreateInstance*: TPCreateInstance
            LockServer*: TPLockServer

        TClassFactory* = object
            lpVtbl*: ptr TClassFactoryVtbl

    proc QueryInterfaceImpl(this: pointer, riid: pointer, ppv: ptr pointer): HRESULT {.stdcall.} =
        if ppv == nil:
            return E_POINTER
        # For simplicity, accept any interface query
        ppv[] = this
        return S_OK

    proc AddRefImpl(this: pointer): ULONG {.stdcall.} = 
        g_refCount.inc()
        return cast[ULONG](g_refCount)
    
    proc ReleaseImpl(this: pointer): ULONG {.stdcall.} = 
        g_refCount.dec()
        return cast[ULONG](g_refCount)

    # AMSI Scan implementation - uses nim_antimalware_sim scanner
    proc ScanImpl(this: pointer, session: HAMSISESSION, buffer: pointer, length: ULONG, 
                  contentName: LPCWSTR, session2: HAMSISESSION, pResult: ptr UINT): HRESULT {.stdcall.} =
        ## Called by AMSI when content needs to be scanned
        ## Parameters:
        ##   buffer: pointer to the data to scan
        ##   length: length of the buffer in bytes
        ##   contentName: optional name of the content (wide string)
        ##   pResult: pointer to store scan result
        try:
            echo "AMSI Provider: ScanImpl called with ", length, " bytes"
            
            if buffer == nil or pResult == nil:
                echo "AMSI Provider: Invalid arguments (buffer or result is nil)"
                if pResult != nil: 
                    pResult[] = 0  # AMSI_RESULT_CLEAN
                return E_INVALIDARG

            if length == 0:
                echo "AMSI Provider: Empty content, marking as clean"
                pResult[] = 0  # AMSI_RESULT_CLEAN
                return S_OK
            
            # Safety check - limit max scan size
            let actualLength = if length > 1048576: 1048576 else: length  # Max 1MB
            
            # Read content from buffer (safely using provided length)
            var content = newSeq[byte](actualLength)
            try:
                copyMem(addr content[0], buffer, actualLength)
            except:
                echo "AMSI Provider: Failed to copy buffer"
                pResult[] = 0  # AMSI_RESULT_CLEAN on error
                return E_FAIL
            
            # Write to temp file so we can use the existing scanner
            let tempPath = getTempDir() / "amsi_scan_" & $getCurrentProcessId() & ".tmp"
            try:
                let f = open(tempPath, fmWrite)
                discard f.writeBytes(content, 0, content.len)
                f.close()
                
                # Use the existing scanner from nim_antimalware_sim
                var provider = LoggingAntimalwareProvider(name: "MostShittyAV AMSI Provider")
                let isClean = provider.scan(tempPath)
                
                # Clean up temp file
                try:
                    removeFile(tempPath)
                except:
                    discard  # Ignore cleanup errors
                
                # Set AMSI result
                if isClean:
                    pResult[] = 0  # AMSI_RESULT_CLEAN
                    echo "AMSI Provider: Result = CLEAN"
                else:
                    pResult[] = 32768  # AMSI_RESULT_DETECTED
                    echo "AMSI Provider: Result = DETECTED"
                
                return S_OK
                
            except Exception as e:
                # Clean up on error
                if fileExists(tempPath):
                    try: removeFile(tempPath)
                    except: discard
                echo "AMSI Provider: Exception during file operations: ", e.msg
                pResult[] = 0  # AMSI_RESULT_CLEAN on error (fail-open)
                return E_FAIL
            
        except Exception as e:
            echo "AMSI Provider: Exception in ScanImpl: ", e.msg
            if pResult != nil: 
                pResult[] = 0  # AMSI_RESULT_CLEAN (fail-open for safety)
            return E_FAIL

    proc CloseSessionImpl(this: pointer, session: HAMSISESSION): HRESULT {.stdcall.} =
        return S_OK

    proc DisplayNameImpl(this: pointer, name: ptr BSTR): HRESULT {.stdcall.} =
        if name != nil:
            name[] = SysAllocString("MostShittyAV Nim Demo Provider (Wrapper)")
        return S_OK

    # Forward declarations for variables
    var ClassFactoryVtbl*: TClassFactoryVtbl
    var ClassFactory*: TClassFactory
    var DemoVtbl*: TAmsiProviderVtbl
    var DemoProvider*: TAmsiProvider

    # IClassFactory implementation
    proc CreateInstanceImpl(this: pointer, pUnkOuter: pointer, riid: pointer, ppv: ptr pointer): HRESULT {.stdcall.} =
        if ppv == nil:
            return E_POINTER
        
        if pUnkOuter != nil:
            return CLASS_E_NOAGGREGATION
        
        # Return our AMSI provider instance
        ppv[] = cast[pointer](addr DemoProvider)
        discard AddRefImpl(ppv[])
        echo "CreateInstance: Returning AMSI Provider instance"
        return S_OK

    proc LockServerImpl(this: pointer, fLock: BOOL): HRESULT {.stdcall.} =
        if fLock != 0:
            g_refCount.inc()
        else:
            g_refCount.dec()
        return S_OK

    # Initialize vtables
    ClassFactoryVtbl = TClassFactoryVtbl(
        QueryInterface: QueryInterfaceImpl,
        AddRef: AddRefImpl,
        Release: ReleaseImpl,
        CreateInstance: CreateInstanceImpl,
        LockServer: LockServerImpl
    )

    ClassFactory = TClassFactory(lpVtbl: addr ClassFactoryVtbl)

    DemoVtbl = TAmsiProviderVtbl(
        QueryInterface: QueryInterfaceImpl,
        AddRef: AddRefImpl,
        Release: ReleaseImpl,
        Scan: ScanImpl,
        CloseSession: CloseSessionImpl,
        DisplayName: DisplayNameImpl
    )

    DemoProvider = TAmsiProvider(lpVtbl: addr DemoVtbl)

    proc getOurModuleHandle(): HMODULE =
        var hm: HMODULE
        let funcAddr = cast[LPCSTR](getOurModuleHandle)
        if GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS or 
                                                    GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                                                    funcAddr, addr hm) != 0:
            return hm
        return 0

    proc DllGetClassObject(rclsid: pointer, riid: pointer, ppv: ptr pointer): HRESULT {.exportc, stdcall, dynlib.} =
        if ppv == nil:
            return E_POINTER
        
        # Return IClassFactory, not the provider directly
        ppv[] = cast[pointer](addr ClassFactory)
        discard AddRefImpl(ppv[])
        echo "DllGetClassObject (wrapper) called - returning ClassFactory"
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
