when defined(windows):
    import winim/lean
    import winim/com
    import times
    import strformat
    import strutils

    {.passC: "-DWIN32_LEAN_AND_MEAN".}
    {.passL: "-lole32 -loleaut32".}

    const PROVIDER_GUID = "{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"
    const PROVIDER_NAME = "NimAmsiDemoProvider"

    var g_hModule: HMODULE = 0
    var g_callCounter: int = 0

    # AMSI Result Codes
    const
        AMSI_RESULT_CLEAN* = 0
        AMSI_RESULT_NOT_DETECTED* = 1
        AMSI_RESULT_BLOCKED_BY_ADMIN_START* = 16384
        AMSI_RESULT_BLOCKED_BY_ADMIN_END* = 20479
        AMSI_RESULT_DETECTED* = 32768
        CLASS_E_NOAGGREGATION* = 0x80040110'i32

    type
        HAMSICONTEXT* = pointer
        HAMSISESSION* = pointer

    # IAntimalware interface GUID: {82d29c2e-f062-44e6-b5c9-3d9a2f24a2df}
    var IID_IAntimalware: GUID
    IID_IAntimalware.Data1 = cast[int32](0x82d29c2e'u32)
    IID_IAntimalware.Data2 = cast[uint16](0xf062)
    IID_IAntimalware.Data3 = cast[uint16](0x44e6)
    IID_IAntimalware.Data4 = [0xb5'u8, 0xc9, 0x3d, 0x9a, 0x2f, 0x24, 0xa2, 0xdf]

    type
        # IAntimalware interface definition (Windows 8+)
        # The Scan method parameters based on actual AMSI provider interface
        IAntimalwareVtbl* = object
            QueryInterface*: proc(this: pointer, riid: ptr GUID, ppv: ptr pointer): HRESULT {.stdcall.}
            AddRef*: proc(this: pointer): ULONG {.stdcall.}
            Release*: proc(this: pointer): ULONG {.stdcall.}
            Scan*: proc(this: pointer, stream: pointer, result: ptr ULONG): HRESULT {.stdcall.}
            CloseSession*: proc(this: pointer, session: HAMSISESSION): void {.stdcall.}
            DisplayName*: proc(this: pointer, displayName: ptr LPWSTR): HRESULT {.stdcall.}

        IAntimalware* = object
            lpVtbl*: ptr IAntimalwareVtbl
        
        # IClassFactory for creating instances
        IClassFactoryVtbl* = object
            QueryInterface*: proc(this: pointer, riid: ptr GUID, ppv: ptr pointer): HRESULT {.stdcall.}
            AddRef*: proc(this: pointer): ULONG {.stdcall.}
            Release*: proc(this: pointer): ULONG {.stdcall.}
            CreateInstance*: proc(this: pointer, pUnkOuter: pointer, riid: ptr GUID, ppv: ptr pointer): HRESULT {.stdcall.}
            LockServer*: proc(this: pointer, fLock: BOOL): HRESULT {.stdcall.}
        
        IClassFactory* = object
            lpVtbl*: ptr IClassFactoryVtbl

    # Logging helper
    proc logMessage(msg: string) =
        let timestamp = now().format("yyyy-MM-dd HH:mm:ss")
        echo &"[{timestamp}] {msg}"

    proc getPointerInfo(p: pointer): string =
        if p == nil:
            return "NULL"
        else:
            return &"0x{cast[int](p):X}"

    proc wideStrToString(ws: LPCWSTR): string =
        if ws == nil:
            return "<null>"
        
        # Check if pointer looks valid (not in low memory or clearly invalid)
        let ptrVal = cast[int](ws)
        if ptrVal < 0x10000 or ptrVal == 0x9:  # Invalid pointer ranges
            return &"<invalid_ptr:0x{ptrVal:X}>"
        
        try:
            var i = 0
            result = ""
            let p = cast[ptr UncheckedArray[uint16]](ws)
            while p[i] != 0 and i < 1024:
                let ch = p[i] and 0xFF
                if ch >= 32 and ch < 127:  # Printable ASCII
                    result.add(chr(ch))
                else:
                    result.add('?')
                inc i
        except:
            return &"<error_reading:0x{ptrVal:X}>"

    # Forward declarations for global variables
    var g_AmsiVtbl*: IAntimalwareVtbl
    var g_AmsiProvider*: IAntimalware
    var g_ClassFactoryVtbl*: IClassFactoryVtbl
    var g_ClassFactory*: IClassFactory

    # COM Interface Implementations for IAntimalware
    proc AM_AddRef(this: pointer): ULONG {.stdcall.} =
        logMessage(&"IAntimalware::AddRef - this: {getPointerInfo(this)}")
        return 1

    proc AM_Release(this: pointer): ULONG {.stdcall.} =
        logMessage(&"IAntimalware::Release - this: {getPointerInfo(this)}")
        return 1

    proc AM_QueryInterface(this: pointer, riid: ptr GUID, ppv: ptr pointer): HRESULT {.stdcall.} =
        logMessage(&"IAntimalware::QueryInterface - this: {getPointerInfo(this)}")
        
        if ppv == nil:
            logMessage("  ERROR: ppv is NULL")
            return E_POINTER
        
        ppv[] = nil
        
        if riid != nil:
            let guid = cast[ptr GUID](riid)[]
            logMessage(&"  Requested IID: {{{guid.Data1:08X}-{guid.Data2:04X}-{guid.Data3:04X}-{guid.Data4[0]:02X}{guid.Data4[1]:02X}-{guid.Data4[2]:02X}{guid.Data4[3]:02X}{guid.Data4[4]:02X}{guid.Data4[5]:02X}{guid.Data4[6]:02X}{guid.Data4[7]:02X}}}")
            
            # Accept any interface request - return ourselves as IAntimalware
            # This is a permissive approach for demo purposes
            ppv[] = this
            discard AM_AddRef(this)
            logMessage("  SUCCESS: Returning IAntimalware interface")
            return S_OK
        
        logMessage("  FAILED: riid is NULL - E_NOINTERFACE")
        return E_NOINTERFACE

    # Main AMSI Scan Implementation - MINIMAL SIGNATURE
    # The stream parameter is actually an IAmsiStream COM interface
    proc AM_Scan(this: pointer, stream: pointer, pResult: ptr ULONG): HRESULT {.stdcall.} =
        g_callCounter.inc()
        
        logMessage("=" .repeat(80))
        logMessage(&"AMSI SCAN REQUEST #{g_callCounter}")
        logMessage("=" .repeat(80))
        
        # Log memory locations
        logMessage(&"Memory Locations:")
        logMessage(&"  this:                {getPointerInfo(this)}")
        logMessage(&"  stream (IAmsiStream): {getPointerInfo(stream)}")
        logMessage(&"  pResult:             {getPointerInfo(pResult)}")
        
        # Get current process info
        var processId = GetCurrentProcessId()
        
        logMessage(&"Process Information:")
        logMessage(&"  Process ID:          {processId}")
        
        # Log thread info
        var threadId = GetCurrentThreadId()
        logMessage(&"Thread Information:")
        logMessage(&"  Thread ID:           {threadId}")
        
        # Validate parameters
        if pResult == nil:
            logMessage("ERROR: Result pointer is NULL!")
            logMessage("=" .repeat(80))
            return E_INVALIDARG
        
        # Check if pResult pointer is valid
        let ptrVal = cast[int](pResult)
        if ptrVal < 0x10000:
            logMessage(&"ERROR: Invalid result pointer: 0x{ptrVal:X}")
            logMessage("=" .repeat(80))
            return E_POINTER
        
        # Always return CLEAN for this demo
        try:
            pResult[] = AMSI_RESULT_CLEAN
            logMessage(&"Scan Decision:")
            logMessage(&"  Result:              {pResult[]} (AMSI_RESULT_CLEAN)")
            logMessage(&"  Return:              S_OK (0x{S_OK:X})")
            logMessage("=" .repeat(80))
            return S_OK
        except:
            logMessage("EXCEPTION: Failed to write result!")
            logMessage("=" .repeat(80))
            return E_FAIL

    proc AM_CloseSession(this: pointer, session: HAMSISESSION): void {.stdcall.} =
        logMessage(&"IAntimalware::CloseSession - session: {getPointerInfo(session)}")

    proc AM_DisplayName(this: pointer, displayName: ptr LPWSTR): HRESULT {.stdcall.} =
        logMessage(&"IAntimalware::DisplayName called")
        
        if displayName != nil:
            # Allocate BSTR using COM allocator
            let nameStr: BSTR = SysAllocString("Nim AMSI Demo Provider")
            displayName[] = cast[LPWSTR](nameStr)
            logMessage(&"  Returning: 'Nim AMSI Demo Provider'")
        
        return S_OK

    # IClassFactory Implementations
    proc CF_AddRef(this: pointer): ULONG {.stdcall.} =
        return 1

    proc CF_Release(this: pointer): ULONG {.stdcall.} =
        return 1

    proc CF_QueryInterface(this: pointer, riid: ptr GUID, ppv: ptr pointer): HRESULT {.stdcall.} =
        logMessage(&"IClassFactory::QueryInterface - this: {getPointerInfo(this)}")
        
        if ppv == nil:
            return E_POINTER
        
        ppv[] = this
        discard CF_AddRef(this)
        logMessage("  SUCCESS: Returning IClassFactory")
        return S_OK

    proc CF_CreateInstance(this: pointer, pUnkOuter: pointer, riid: ptr GUID, ppv: ptr pointer): HRESULT {.stdcall.} =
        logMessage(&"IClassFactory::CreateInstance - creating IAntimalware instance")
        
        if pUnkOuter != nil:
            logMessage("  ERROR: Aggregation not supported")
            return CLASS_E_NOAGGREGATION
        
        if ppv == nil:
            return E_POINTER
        
        # Return the IAntimalware interface
        ppv[] = cast[pointer](addr g_AmsiProvider)
        discard AM_AddRef(ppv[])
        
        logMessage(&"  SUCCESS: Created IAntimalware at {getPointerInfo(ppv[])}")
        return S_OK

    proc CF_LockServer(this: pointer, fLock: BOOL): HRESULT {.stdcall.} =
        logMessage(&"IClassFactory::LockServer - fLock: {fLock}")
        return S_OK

    # Initialize the vtables
    g_AmsiVtbl = IAntimalwareVtbl(
        QueryInterface: AM_QueryInterface,
        AddRef: AM_AddRef,
        Release: AM_Release,
        Scan: AM_Scan,
        CloseSession: AM_CloseSession,
        DisplayName: AM_DisplayName
    )

    g_AmsiProvider = IAntimalware(lpVtbl: addr g_AmsiVtbl)
    
    g_ClassFactoryVtbl = IClassFactoryVtbl(
        QueryInterface: CF_QueryInterface,
        AddRef: CF_AddRef,
        Release: CF_Release,
        CreateInstance: CF_CreateInstance,
        LockServer: CF_LockServer
    )
    
    g_ClassFactory = IClassFactory(lpVtbl: addr g_ClassFactoryVtbl)

    # Helper to get module handle
    proc getOurModuleHandle(): HMODULE =
        var hm: HMODULE
        let funcAddr = cast[LPCSTR](getOurModuleHandle)
        if GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS or 
                              GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                              funcAddr, addr hm) != 0:
            return hm
        return 0

    # DLL Exports
    proc DllGetClassObject(rclsid: ptr GUID, riid: ptr GUID, ppv: ptr pointer): HRESULT {.exportc, stdcall, dynlib.} =
        logMessage("=" .repeat(80))
        logMessage("DllGetClassObject called")
        
        if rclsid != nil:
            let guid = rclsid[]
            logMessage(&"  CLSID requested: {{{guid.Data1:08X}-{guid.Data2:04X}-{guid.Data3:04X}-...}}")
        
        if ppv == nil:
            logMessage("  ERROR: ppv is NULL")
            return E_POINTER
        
        # Return the class factory
        ppv[] = cast[pointer](addr g_ClassFactory)
        discard CF_AddRef(ppv[])
        
        logMessage(&"  Returning IClassFactory at: {getPointerInfo(ppv[])}")
        logMessage("  Result: S_OK")
        logMessage("=" .repeat(80))
        return S_OK

    proc DllCanUnloadNow(): HRESULT {.exportc, stdcall, dynlib.} =
        logMessage("DllCanUnloadNow called - Result: S_FALSE (don't unload)")
        return S_FALSE

    proc DllRegisterServer(): HRESULT {.exportc, stdcall, dynlib.} =
        logMessage("=" .repeat(80))
        logMessage("DllRegisterServer - Registering AMSI Provider")
        logMessage("=" .repeat(80))
        
        try:
            var hKey: HKEY
            var disposition: DWORD
            
            # Register CLSID
            let clsidPath = "SOFTWARE\\Classes\\CLSID\\" & PROVIDER_GUID
            logMessage(&"Creating CLSID key: {clsidPath}")
            
            var regResult = RegCreateKeyExA(HKEY_LOCAL_MACHINE, clsidPath, 0, nil, 
                                            REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, 
                                            addr hKey, addr disposition)
            if regResult != ERROR_SUCCESS:
                logMessage(&"ERROR: Failed to create CLSID key: {regResult}")
                return HRESULT(ERROR_ACCESS_DENIED)
            
            let providerNameStr = "Nim AMSI Demo Provider"
            discard RegSetValueExA(hKey, nil, 0, REG_SZ, 
                                   cast[LPBYTE](unsafeAddr providerNameStr[0]), 
                                   DWORD(providerNameStr.len + 1))
            discard RegCloseKey(hKey)
            logMessage("  CLSID key created successfully")
            
            # Register InprocServer32
            let inprocPath = clsidPath & "\\InprocServer32"
            logMessage(&"Creating InprocServer32 key: {inprocPath}")
            
            regResult = RegCreateKeyExA(HKEY_LOCAL_MACHINE, inprocPath, 0, nil, 
                                        REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, 
                                        addr hKey, addr disposition)
            if regResult != ERROR_SUCCESS:
                logMessage(&"ERROR: Failed to create InprocServer32 key: {regResult}")
                return HRESULT(ERROR_ACCESS_DENIED)
            
            if g_hModule == 0:
                g_hModule = getOurModuleHandle()
            
            var dllPath: array[MAX_PATH, char]
            let pathLen = GetModuleFileNameA(g_hModule, cast[LPSTR](addr dllPath[0]), MAX_PATH)
            if pathLen == 0 or pathLen >= MAX_PATH:
                logMessage(&"ERROR: Failed to get DLL path: {GetLastError()}")
                discard RegCloseKey(hKey)
                return HRESULT(ERROR_BAD_PATHNAME)
            
            let dllPathStr = $cast[cstring](addr dllPath[0])
            logMessage(&"  DLL Path: {dllPathStr}")
            
            discard RegSetValueExA(hKey, nil, 0, REG_SZ, 
                                   cast[LPBYTE](addr dllPath[0]), 
                                   DWORD(pathLen + 1))
            
            let threadingModel = "Both"
            discard RegSetValueExA(hKey, "ThreadingModel", 0, REG_SZ, 
                                   cast[LPBYTE](unsafeAddr threadingModel[0]), 
                                   DWORD(threadingModel.len + 1))
            discard RegCloseKey(hKey)
            logMessage("  InprocServer32 key created successfully")
            
            # Register AMSI Provider
            let amsiPath = "SOFTWARE\\Microsoft\\AMSI\\Providers\\" & PROVIDER_GUID
            logMessage(&"Creating AMSI Provider key: {amsiPath}")
            
            regResult = RegCreateKeyExA(HKEY_LOCAL_MACHINE, amsiPath, 0, nil, 
                                        REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, 
                                        addr hKey, addr disposition)
            if regResult != ERROR_SUCCESS:
                logMessage(&"ERROR: Failed to create AMSI Provider key: {regResult}")
                return HRESULT(ERROR_ACCESS_DENIED)
            
            let providerNameCopy = PROVIDER_NAME
            discard RegSetValueExA(hKey, nil, 0, REG_SZ, 
                                   cast[LPBYTE](unsafeAddr providerNameCopy[0]), 
                                   DWORD(providerNameCopy.len + 1))
            discard RegCloseKey(hKey)
            logMessage("  AMSI Provider key created successfully")
            
            logMessage("=" .repeat(80))
            logMessage("Registration SUCCESSFUL!")
            logMessage(&"  Provider GUID: {PROVIDER_GUID}")
            logMessage(&"  Provider Name: {PROVIDER_NAME}")
            logMessage("=" .repeat(80))
            return S_OK
            
        except OSError as e:
            logMessage(&"EXCEPTION: {e.msg}")
            return HRESULT(ERROR_ACCESS_DENIED)
        except:
            logMessage("EXCEPTION: Unknown error")
            return E_FAIL

    proc DllUnregisterServer(): HRESULT {.exportc, stdcall, dynlib.} =
        logMessage("=" .repeat(80))
        logMessage("DllUnregisterServer - Unregistering AMSI Provider")
        logMessage("=" .repeat(80))
        
        try:
            let amsiPath = "SOFTWARE\\Microsoft\\AMSI\\Providers\\" & PROVIDER_GUID
            discard RegDeleteKeyA(HKEY_LOCAL_MACHINE, amsiPath)
            logMessage(&"  Deleted AMSI Provider key: {amsiPath}")
            
            let inprocPath = "SOFTWARE\\Classes\\CLSID\\" & PROVIDER_GUID & "\\InprocServer32"
            discard RegDeleteKeyA(HKEY_LOCAL_MACHINE, inprocPath)
            logMessage(&"  Deleted InprocServer32 key")
            
            let clsidPath = "SOFTWARE\\Classes\\CLSID\\" & PROVIDER_GUID
            discard RegDeleteKeyA(HKEY_LOCAL_MACHINE, clsidPath)
            logMessage(&"  Deleted CLSID key")
            
            logMessage("=" .repeat(80))
            logMessage("Unregistration SUCCESSFUL!")
            logMessage("=" .repeat(80))
            return S_OK
            
        except OSError as e:
            logMessage(&"EXCEPTION: {e.msg}")
            return HRESULT(ERROR_ACCESS_DENIED)
        except:
            logMessage("EXCEPTION: Unknown error")
            return E_FAIL

else:
    echo "This AMSI provider is intended for Windows only."
