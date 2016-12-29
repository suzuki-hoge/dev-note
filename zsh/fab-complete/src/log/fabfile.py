from fabric.api import task

print '==========='
print 'some header'
print '==========='

@task
def search(yyyymmdd, keyword):
    """(yyyymmdd, keyword)"""
    pass

@task
def fetch(yyyymmdd = None):
    """(yyyymmdd = today)"""
    pass

@task
def put(yyyymmdd = None):
    pass
