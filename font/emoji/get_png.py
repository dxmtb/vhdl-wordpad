import os
for i in xrange(5):
    for j in xrange(16):
        s = 'http://www.fileformat.info/info/unicode/font/dejavu_sans/u1F6%d%s.png' % (i, hex(j)[2:])
        os.system("wget %s" % s)
