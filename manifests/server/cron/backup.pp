# setup a basic cronjob to backup mysql database
class mysql::server::cron::backup {
  if $mysql::server::manage_backup_dir {
    file { 'mysql_backup_dir':
      ensure  => directory,
      path    => $mysql::server::backup_dir,
      before  => Cron['mysql_backup_cron'],
      owner   => root,
      group   => 0,
      mode    => '0700';
    }
  }
  
  if $mysql::server::dated_backups {
    $backup_name = "mysqldump_`date '+%Y%m%d%H%M'`.sql.gz"
    if $mysql::server::retained_backups > 0 {
	$clean_command = "find ${mysql::server::backup_dir} -name 'mysqldump_*' | sort -n | head -n -${mysql::server::retained_backups} | xargs -r rm"
    }
    
  } else {
    $backup_name = "mysqldump.sql.gz"
  }

  cron { 'mysql_backup_cron':
    command => "/usr/bin/mysqldump --default-character-set=utf8 --all-databases --events --flush-logs --lock-tables --single-transaction | gzip > ${mysql::server::backup_dir}/${backup_name} && chmod 600 ${mysql::server::backup_dir}/mysqldump_*.sql.gz; ${clean_command}",
    user    => 'root',
    minute  => 0,
    hour    => 1,
    require => [ Exec['mysql_set_rootpw'], File['mysql_root_cnf'] ],
  }
}
