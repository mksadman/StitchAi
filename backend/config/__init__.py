# Enable PyMySQL as a drop-in replacement for MySQLdb when using Django's MySQL backend.
# This allows using the pure-Python PyMySQL driver without changing Django settings.
try:
	import pymysql  # type: ignore

	pymysql.install_as_MySQLdb()
except Exception:
	# If PyMySQL isn't installed, silently ignore so environments using mysqlclient still work.
	pass

