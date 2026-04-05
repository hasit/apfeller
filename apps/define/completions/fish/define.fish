set -l __define_languages auto en es fr de it pt ja ko zh tr nl sv da nb vi

complete -c define -s i -l in -x -a "$__define_languages" -d 'Input language'
complete -c define -s o -l out -x -a "$__define_languages" -d 'Output language'
complete -c define -s c -l copy -d 'Copy the response to the clipboard'
complete -c define -s h -l help -d 'Show help'
