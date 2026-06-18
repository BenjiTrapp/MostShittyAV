#!/usr/bin/python3
filename = '05_extensionfailed_RTLO_\u202Ebypass.sh'
with open(filename, 'w') as f:
    f.write('#!/usr/bin/bash\necho "THIS COULD BE A MALICIOUS FUNCTION CALL"')
