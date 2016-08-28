import commands
from itertools import groupby
import re

markdowns = [e[2:] for e in commands.getoutput('find . -name "*.md"').split('\n') if e.count('/') == 2]

def toHeader(dir):
    return ['\n## [%s](%s)\n' % (dir, dir)]

def toList(dir, files):
    def _toList(file):
        label = re.sub('^\d+_', '', file)
        return '+ [%s](%s/%s)\n' % (label, dir, file)
    return map(_toList, files)

f = open('README.md', 'w')
f.write('# DevNote\n')

for key, group in groupby(markdowns, lambda x: x.split('/')[0]):
    dir = key
    files = [e.split('/')[1] for e in list(group)]

    f.writelines(toHeader(dir))
    f.writelines(toList(dir, files))

f.write('\n-> [wiki](https://github.com/suzuki-hoge/dev-note/wiki)')
f.close()
