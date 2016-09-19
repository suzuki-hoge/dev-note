from fabric.api import task

@task
def search(yyyymmdd, keyword):
    """(yyyymmdd, keyword)"""
    pass

@task
def fetch(yyyymmdd = None):
    """(yyyymmdd = today)"""
    pass
