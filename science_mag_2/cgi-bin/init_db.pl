#!/usr/bin/perl
use strict;
use warnings;
use DB_File;
use Fcntl qw(:DEFAULT :flock);

# Print HTTP header first
print "Content-type: text/plain\n\n";

# Define data paths for Docker environment
my $data_dir = "/usr/local/apache2/data";
my $db_path = "$data_dir/users.db";
my $orders_path = "$data_dir/orders.db";
my $articles_path = "$data_dir/articles.db";
my $issues_path = "$data_dir/issues.db";

# Create data directory if it doesn't exist
print "Checking data directory $data_dir...\n";
unless (-d $data_dir) {
    print "Data directory does not exist, creating...\n";
    mkdir $data_dir or die "Cannot create data directory '$data_dir': $! (uid: $>, euid: $<)\n";
    print "Data directory created successfully.\n";
} else {
    print "Data directory exists. Owner: " . (getpwuid((stat($data_dir))[4]))[0] . "\n";
    print "Current process UID: $>, EUID: $<\n";
}

# Check directory permissions
my ($mode, $uid, $gid) = (stat($data_dir))[2, 4, 5];
printf "Directory permissions: %04o, UID: %s, GID: %s\n", $mode & 07777, $uid, $gid;

# Initialize users database
print "Initializing users database...\n";
my %users;
my $users_result = tie %users, 'DB_File', $db_path, O_CREAT|O_RDWR, 0644, $DB_HASH;
if (!$users_result) {
    die "Cannot open users database '$db_path': $! (uid: $>, euid: $<)\n";
}

# Add admin user
$users{"admin\@example.com"} = join(":::", "admin123", "admin", "Admin", "User", "admin");

# Editor user (password: editor123)
$users{'editor\@example.com'} = join(":::", "editor123", "Редактор", "Editor", "User", "editor");

# Regular users (password: password123)
$users{'user1\@example.com'} = join(":::", "password123", "Иванов Иван", "Ivan", "Ivanov", "customer");
$users{'user2\@example.com'} = join(":::", "password123", "Петров Петр", "Petr", "Petrov", "customer");
$users{'user3\@example.com'} = join(":::", "password123", "Сидорова Анна", "Anna", "Sidorova", "customer");

untie %users;
print "Users database initialized with 5 users\n";

# Initialize orders database
print "Initializing orders database...\n";
my %orders;
my $orders_result = tie %orders, 'DB_File', $orders_path, O_CREAT|O_RDWR, 0644, $DB_HASH;
if (!$orders_result) {
    die "Cannot open orders database '$orders_path': $!\n";
}

# Format: "user_email:::order_id:::date:::amount:::status"
$orders{'ORD-001'} = "user1\@example.com:::20.10.2025:::500:::Оплачен";
$orders{'ORD-002'} = "user2\@example.com:::15.09.2025:::1000:::Оплачен";
$orders{'ORD-003'} = "user1\@example.com:::21.10.2025:::500:::Оплачен";
$orders{'ORD-004'} = "user3\@example.com:::20.08.2025:::500:::Оплачен";
$orders{'ORD-005'} = "user3\@example.com:::05.11.2025:::1500:::В обработке";

untie %orders;
print "Orders database initialized with 5 orders\n";

# Initialize articles database
print "Initializing articles database...\n";
my %articles;
my $articles_result = tie %articles, 'DB_File', $articles_path, O_CREAT|O_RDWR, 0644, $DB_HASH;
if (!$articles_result) {
    die "Cannot open articles database '$articles_path': $!\n";
}

# Format: "title:::authors:::date:::status:::abstract"
$articles{'article-001'} = "Современные подходы к анализу данных:::Петров А.В., Сидоров С.М.:::01.10.2025:::На рассмотрении:::Данная статья представляет обзор современных методов анализа данных в научных исследованиях.";
$articles{'article-002'} = "Новые методы в квантовых вычислениях:::Иванов И.И.:::25.09.2025:::Принята:::Работа посвящена инновационным подходам в области квантовых вычислений.";
$articles{'article-003'} = "Исследование эффективности алгоритмов машинного обучения:::Смирнова Е.А.:::15.09.2025:::Принята:::В статье проводится сравнительный анализ эффективности различных алгоритмов машинного обучения.";
$articles{'article-004'} = "Применение нейронных сетей в обработке естественного языка:::Козлов И.С.:::10.09.2025:::Отклонена:::Статья рассматривает методы использования нейронных сетей для задач обработки естественного языка.";
$articles{'article-005'} = "Этические аспекты развития искусственного интеллекта:::Новикова М.П., Орлов К.Д.:::30.10.2025:::На рассмотрении:::Исследование посвящено этическим вопросам, возникающим при развитии систем ИИ.";

untie %articles;
print "Articles database initialized with 5 articles\n";

# Initialize issues database
print "Initializing issues database...\n";
my %issues;
my $issues_result = tie %issues, 'DB_File', $issues_path, O_CREAT|O_RDWR, 0644, $DB_HASH;
if (!$issues_result) {
    die "Cannot open issues database '$issues_path': $!\n";
}

# Format: "number:::date:::title:::description:::articles:::price"
$issues{'issue-001'} = "Том 15, Выпуск 1:::01.03.2025:::Информационные технологии в науке:::Выпуск посвящен применению ИТ в научных исследованиях:::article-002,article-003:::500";
$issues{'issue-002'} = "Том 15, Выпуск 2:::01.06.2025:::Инновации в компьютерных науках:::Специальный выпуск по инновационным методам в компьютерных науках:::article-003:::500";
$issues{'issue-003'} = "Том 15, Выпуск 3:::01.09.2025:::Технологии будущего:::Исследования и разработки, определяющие будущее технологий:::article-002:::500";
$issues{'issue-004'} = "Том 15, Выпуск 4:::01.12.2025:::Искусственный интеллект:::Современные достижения в области ИИ:::article-003:::500";

untie %issues;
print "Issues database initialized with 4 issues\n";

print "Database initialization completed successfully.\n";
# List created files
print "Created files in $data_dir:\n";
if (opendir(my $dh, $data_dir)) {
    while (my $file = readdir($dh)) {
        next if $file =~ /^\.\.?$/;
        my ($mode, $uid, $gid) = (stat("$data_dir/$file"))[2, 4, 5];
        printf " - %s (mode: %04o, UID: %s, GID: %s)\n", $file, $mode & 07777, $uid, $gid;
    }
    closedir($dh);
} else {
    print "Could not open directory '$data_dir': $!\n";
} 