import subprocess

response = subprocess.run('sqlplus -S -L lwilhoit@dprprod2/nashira8 @test2', 
                          stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=True)


stdout_str = response.stdout.decode('UTF-8') 
stderr_str = response.stderr.decode('UTF-8')
print('***********************************') 
print('stdout_str:')
print(stdout_str)
print('***********************************') 
print('stderr_str:')
print(stderr_str)
print('\nreturncode = ' + str(response.returncode))

# Attempt to print output while script is running,
# but does not work that way
#while True:
#    output = response.stdout.readline()
#    if output == '' and response.poll() is not None:
#        break
#    if output:
#        print (output.strip())
#rc = response.poll()
#print('rc = ', rc)
#
#
