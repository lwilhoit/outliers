
def testfun(first, second, *others):
    other_str = ''
    for i in others:
        other_str = other_str + ' ' + str(i)
    print(first + second + other_str)

testfun('one', 'two')
testfun('one', 'two', '1')
testfun('one', 'two', '1', '2')
testfun('one', 'two', 'a', '1', '2', 3)


