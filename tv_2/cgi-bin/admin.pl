#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use DB_File;
use Encode qw(decode encode);
use File::Basename;
use Cwd qw(abs_path);
use POSIX qw(strftime);
use lib dirname(__FILE__);
use Common;

# Включаем вывод ошибок в браузер
BEGIN {
    $ENV{PERL_CGI_STDERR_TO_BROWSER} = 1;
}

binmode(STDOUT, ":utf8");
print "Content-type: text/html; charset=utf-8\n\n";

my $q = CGI->new;
my $action = $q->param('action') || '';
my $message = '';
my $error = '';
my $date = strftime("%Y-%m-%d", localtime);

# Функция для добавления нового канала
sub add_channel {
    my $name = $q->param('name') || '';
    my $logo = $q->param('logo') || '/img/default_channel.png';
    my $description = $q->param('description') || '';
    
    $name = Encode::decode('UTF-8', $name) unless Encode::is_utf8($name);
    $logo = Encode::decode('UTF-8', $logo) unless Encode::is_utf8($logo);
    $description = Encode::decode('UTF-8', $description) unless Encode::is_utf8($description);
    
    if ($name) {
        my %channels;
        tie %channels, 'DB_File', $Common::channels_db, O_RDWR, 0666, $DB_HASH
            or die "Не удалось открыть $Common::channels_db: $!";
        
        # Находим максимальный ID
        my $max_id = 0;
        foreach my $id (keys %channels) {
            $max_id = $id if $id > $max_id;
        }
        
        # Создаем новый канал
        my $new_id = $max_id + 1;
        my $channel = {
            id => $new_id,
            name => $name,
            logo => $logo,
            description => $description
        };
        
        my $data = Common::encode_json($channel);
        $channels{$new_id} = Encode::encode('UTF-8', $data);
        
        untie %channels;
        
        $message = "Канал \"$name\" успешно добавлен.";
    } else {
        $error = "Не указано название канала.";
    }
}

# Функция для добавления новой категории
sub add_category {
    my $name = $q->param('name') || '';
    my $icon = $q->param('icon') || '/img/default_category.png';
    my $description = $q->param('description') || '';
    
    $name = Encode::decode('UTF-8', $name) unless Encode::is_utf8($name);
    $icon = Encode::decode('UTF-8', $icon) unless Encode::is_utf8($icon);
    $description = Encode::decode('UTF-8', $description) unless Encode::is_utf8($description);
    
    if ($name) {
        my %categories;
        tie %categories, 'DB_File', $Common::categories_db, O_RDWR, 0666, $DB_HASH
            or die "Не удалось открыть $Common::categories_db: $!";
        
        # Находим максимальный ID
        my $max_id = 0;
        foreach my $id (keys %categories) {
            $max_id = $id if $id > $max_id;
        }
        
        # Создаем новую категорию
        my $new_id = $max_id + 1;
        my $category = {
            id => $new_id,
            name => $name,
            icon => $icon,
            description => $description
        };
        
        my $data = Common::encode_json($category);
        $categories{$new_id} = Encode::encode('UTF-8', $data);
        
        untie %categories;
        
        $message = "Категория \"$name\" успешно добавлена.";
    } else {
        $error = "Не указано название категории.";
    }
}

# Функция для добавления новой программы
sub add_program {
    my $name = $q->param('name') || '';
    my $category_id = $q->param('category_id') || '';
    my $duration = $q->param('duration') || '';
    my $description = $q->param('description') || '';
    
    $name = Encode::decode('UTF-8', $name) unless Encode::is_utf8($name);
    $description = Encode::decode('UTF-8', $description) unless Encode::is_utf8($description);
    
    if ($name && $category_id && $duration) {
        my %programs;
        tie %programs, 'DB_File', $Common::programs_db, O_RDWR, 0666, $DB_HASH
            or die "Не удалось открыть $Common::programs_db: $!";
        
        # Находим максимальный ID
        my $max_id = 0;
        foreach my $id (keys %programs) {
            $max_id = $id if $id > $max_id;
        }
        
        # Создаем новую программу
        my $new_id = $max_id + 1;
        my $program = {
            id => $new_id,
            name => $name,
            category_id => $category_id,
            duration => $duration,
            description => $description
        };
        
        my $data = Common::encode_json($program);
        $programs{$new_id} = Encode::encode('UTF-8', $data);
        
        untie %programs;
        
        $message = "Программа \"$name\" успешно добавлена.";
    } else {
        $error = "Не указаны обязательные поля (название, категория, продолжительность).";
    }
}

# Функция для добавления записи в расписание
sub add_schedule {
    my $channel_id = $q->param('channel_id') || '';
    my $program_id = $q->param('program_id') || '';
    my $date = $q->param('date') || '';
    my $start_time = $q->param('start_time') || '';
    my $end_time = $q->param('end_time') || '';
    
    if ($channel_id && $program_id && $date && $start_time && $end_time) {
        my %schedule;
        tie %schedule, 'DB_File', $Common::schedule_db, O_RDWR, 0666, $DB_HASH
            or die "Не удалось открыть $Common::schedule_db: $!";
        
        # Находим максимальный ID
        my $max_id = 0;
        foreach my $id (keys %schedule) {
            $max_id = $id if $id > $max_id;
        }
        
        # Создаем новую запись в расписании
        my $new_id = $max_id + 1;
        my $item = {
            id => $new_id,
            channel_id => $channel_id,
            program_id => $program_id,
            date => $date,
            start_time => $start_time,
            end_time => $end_time
        };
        
        my $data = Common::encode_json($item);
        $schedule{$new_id} = Encode::encode('UTF-8', $data);
        
        untie %schedule;
        
        $message = "Запись успешно добавлена в расписание.";
    } else {
        $error = "Не указаны обязательные поля (канал, программа, дата, время начала, время окончания).";
    }
}

# Функция для удаления канала
sub delete_channel {
    my $id = $q->param('id') || '';
    
    if ($id) {
        my %channels;
        tie %channels, 'DB_File', $Common::channels_db, O_RDWR, 0666, $DB_HASH
            or die "Не удалось открыть $Common::channels_db: $!";
        
        if (exists $channels{$id}) {
            my $data = Encode::decode('UTF-8', $channels{$id});
            my $channel = Common::decode_json($data);
            delete $channels{$id};
            $message = "Канал \"$channel->{name}\" успешно удален.";
        } else {
            $error = "Канал с ID $id не найден.";
        }
        
        untie %channels;
    } else {
        $error = "Не указан ID канала для удаления.";
    }
}

# Функция для удаления категории
sub delete_category {
    my $id = $q->param('id') || '';
    
    if ($id) {
        my %categories;
        tie %categories, 'DB_File', $Common::categories_db, O_RDWR, 0666, $DB_HASH
            or die "Не удалось открыть $Common::categories_db: $!";
        
        if (exists $categories{$id}) {
            my $data = Encode::decode('UTF-8', $categories{$id});
            my $category = Common::decode_json($data);
            delete $categories{$id};
            $message = "Категория \"$category->{name}\" успешно удалена.";
        } else {
            $error = "Категория с ID $id не найдена.";
        }
        
        untie %categories;
    } else {
        $error = "Не указан ID категории для удаления.";
    }
}

# Функция для удаления программы
sub delete_program {
    my $id = $q->param('id') || '';
    
    if ($id) {
        my %programs;
        tie %programs, 'DB_File', $Common::programs_db, O_RDWR, 0666, $DB_HASH
            or die "Не удалось открыть $Common::programs_db: $!";
        
        if (exists $programs{$id}) {
            my $data = Encode::decode('UTF-8', $programs{$id});
            my $program = Common::decode_json($data);
            delete $programs{$id};
            $message = "Программа \"$program->{name}\" успешно удалена.";
        } else {
            $error = "Программа с ID $id не найдена.";
        }
        
        untie %programs;
    } else {
        $error = "Не указан ID программы для удаления.";
    }
}

# Функция для удаления записи из расписания
sub delete_schedule {
    my $id = $q->param('id') || '';
    
    if ($id) {
        my %schedule;
        tie %schedule, 'DB_File', $Common::schedule_db, O_RDWR, 0666, $DB_HASH
            or die "Не удалось открыть $Common::schedule_db: $!";
        
        if (exists $schedule{$id}) {
            delete $schedule{$id};
            $message = "Запись из расписания успешно удалена.";
        } else {
            $error = "Запись с ID $id не найдена.";
        }
        
        untie %schedule;
    } else {
        $error = "Не указан ID записи для удаления.";
    }
}

# Функция для получения всех категорий
sub get_all_categories {
    my %categories;
    my @category_list;
    
    tie %categories, 'DB_File', $Common::categories_db, O_RDONLY, 0666, $DB_HASH
        or die "Не удалось открыть $Common::categories_db: $!";
    
    foreach my $id (sort keys %categories) {
        my $data = Encode::decode('UTF-8', $categories{$id});
        my $category = Common::decode_json($data);
        $category->{id} = $id;
        push @category_list, $category;
    }
    
    untie %categories;
    
    return \@category_list;
}

# Функция для получения всех программ
sub get_all_programs {
    my %programs;
    my @program_list;
    
    tie %programs, 'DB_File', $Common::programs_db, O_RDONLY, 0666, $DB_HASH
        or die "Не удалось открыть $Common::programs_db: $!";
    
    foreach my $id (sort keys %programs) {
        my $data = Encode::decode('UTF-8', $programs{$id});
        my $program = Common::decode_json($data);
        $program->{id} = $id;
        push @program_list, $program;
    }
    
    untie %programs;
    
    return \@program_list;
}

# Функция для получения всего расписания
sub get_all_schedule {
    my %schedule;
    my @schedule_list;
    
    tie %schedule, 'DB_File', $Common::schedule_db, O_RDONLY, 0666, $DB_HASH
        or die "Не удалось открыть $Common::schedule_db: $!";
    
    foreach my $id (sort keys %schedule) {
        my $data = Encode::decode('UTF-8', $schedule{$id});
        my $item = Common::decode_json($data);
        $item->{id} = $id;
        push @schedule_list, $item;
    }
    
    untie %schedule;
    
    # Сортировка по дате и времени начала
    @schedule_list = sort { $a->{date} cmp $b->{date} || $a->{start_time} cmp $b->{start_time} } @schedule_list;
    
    return \@schedule_list;
}

# Обработка действий
if ($action eq 'add_channel') {
    add_channel();
} elsif ($action eq 'add_category') {
    add_category();
} elsif ($action eq 'add_program') {
    add_program();
} elsif ($action eq 'add_schedule') {
    add_schedule();
} elsif ($action eq 'delete_channel') {
    delete_channel();
} elsif ($action eq 'delete_category') {
    delete_category();
} elsif ($action eq 'delete_program') {
    delete_program();
} elsif ($action eq 'delete_schedule') {
    delete_schedule();
}

# Основная функция для отображения административного интерфейса
sub display_admin {
    Common::ensure_db_exists();
    
    my $channels = Common::get_all_channels();
    my $categories = get_all_categories();
    my $programs = get_all_programs();
    my $schedule = get_all_schedule();
    
    print Common::html_header("Управление", "admin");
    
    print <<HTML;
        <main>
            <section>
                <h2>Управление данными</h2>
HTML
    
    if ($message) {
        print <<HTML;
                <div class="success-message">
                    $message
                </div>
HTML
    }
    
    if ($error) {
        print <<HTML;
                <div class="error-message">
                    $error
                </div>
HTML
    }
    
    print <<HTML;
                <div class="admin-section">
                    <div class="admin-tabs">
                        <div class="admin-tab active" data-tab="channels-tab">Каналы</div>
                        <div class="admin-tab" data-tab="categories-tab">Категории</div>
                        <div class="admin-tab" data-tab="programs-tab">Программы</div>
                        <div class="admin-tab" data-tab="schedule-tab">Расписание</div>
                    </div>
                    
                    <div class="admin-content">
                        <!-- Вкладка Каналы -->
                        <div id="channels-tab" class="tab-content">
                            <h3>Добавить новый канал</h3>
                            <form action="/cgi-bin/admin.pl" method="get" class="admin-form">
                                <input type="hidden" name="action" value="add_channel">
                                <div class="form-group">
                                    <label for="channel-name">Название канала:</label>
                                    <input type="text" id="channel-name" name="name" required>
                                </div>
                                <div class="form-group">
                                    <label for="channel-logo">Логотип (URL):</label>
                                    <input type="text" id="channel-logo" name="logo" value="/img/default_channel.png">
                                </div>
                                <div class="form-group">
                                    <label for="channel-description">Описание:</label>
                                    <textarea id="channel-description" name="description" rows="3"></textarea>
                                </div>
                                <button type="submit" class="btn primary">Добавить канал</button>
                            </form>
                            
                            <h3>Список каналов</h3>
                            <table>
                                <tr>
                                    <th>ID</th>
                                    <th>Логотип</th>
                                    <th>Название</th>
                                    <th>Описание</th>
                                    <th>Действия</th>
                                </tr>
HTML
    
    foreach my $channel (@$channels) {
        my $id = $channel->{id};
        my $name = $channel->{name};
        my $logo = $channel->{logo};
        my $description = $channel->{description};
        
        print <<HTML;
                                <tr>
                                    <td>$id</td>
                                    <td><img src="$logo" alt="$name" style="width: 50px; height: 50px;"></td>
                                    <td>$name</td>
                                    <td>$description</td>
                                    <td>
                                        <button onclick="confirmDelete('channel', $id, '$name')" class="btn secondary">Удалить</button>
                                    </td>
                                </tr>
HTML
    }
    
    print <<HTML;
                            </table>
                        </div>
                        
                        <!-- Вкладка Категории -->
                        <div id="categories-tab" class="tab-content" style="display: none;">
                            <h3>Добавить новую категорию</h3>
                            <form action="/cgi-bin/admin.pl" method="get" class="admin-form">
                                <input type="hidden" name="action" value="add_category">
                                <div class="form-group">
                                    <label for="category-name">Название категории:</label>
                                    <input type="text" id="category-name" name="name" required>
                                </div>
                                <div class="form-group">
                                    <label for="category-icon">Иконка (URL):</label>
                                    <input type="text" id="category-icon" name="icon" value="/img/default_category.png">
                                </div>
                                <div class="form-group">
                                    <label for="category-description">Описание:</label>
                                    <textarea id="category-description" name="description" rows="3"></textarea>
                                </div>
                                <button type="submit" class="btn primary">Добавить категорию</button>
                            </form>
                            
                            <h3>Список категорий</h3>
                            <table>
                                <tr>
                                    <th>ID</th>
                                    <th>Иконка</th>
                                    <th>Название</th>
                                    <th>Описание</th>
                                    <th>Действия</th>
                                </tr>
HTML
    
    foreach my $category (@$categories) {
        my $id = $category->{id};
        my $name = $category->{name};
        my $icon = $category->{icon};
        my $description = $category->{description};
        
        print <<HTML;
                                <tr>
                                    <td>$id</td>
                                    <td><img src="$icon" alt="$name" style="width: 30px; height: 30px;"></td>
                                    <td>$name</td>
                                    <td>$description</td>
                                    <td>
                                        <button onclick="confirmDelete('category', $id, '$name')" class="btn secondary">Удалить</button>
                                    </td>
                                </tr>
HTML
    }
    
    print <<HTML;
                            </table>
                        </div>
                        
                        <!-- Вкладка Программы -->
                        <div id="programs-tab" class="tab-content" style="display: none;">
                            <h3>Добавить новую программу</h3>
                            <form action="/cgi-bin/admin.pl" method="get" class="admin-form">
                                <input type="hidden" name="action" value="add_program">
                                <div class="form-group">
                                    <label for="program-name">Название программы:</label>
                                    <input type="text" id="program-name" name="name" required>
                                </div>
                                <div class="form-group">
                                    <label for="program-category">Категория:</label>
                                    <select id="program-category" name="category_id" required>
                                        <option value="">Выберите категорию</option>
HTML
    
    foreach my $category (@$categories) {
        my $id = $category->{id};
        my $name = $category->{name};
        
        print qq(<option value="$id">$name</option>\n);
    }
    
    print <<HTML;
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label for="program-duration">Продолжительность (мин):</label>
                                    <input type="number" id="program-duration" name="duration" min="1" required>
                                </div>
                                <div class="form-group">
                                    <label for="program-description">Описание:</label>
                                    <textarea id="program-description" name="description" rows="3"></textarea>
                                </div>
                                <button type="submit" class="btn primary">Добавить программу</button>
                            </form>
                            
                            <h3>Список программ</h3>
                            <table>
                                <tr>
                                    <th>ID</th>
                                    <th>Название</th>
                                    <th>Категория</th>
                                    <th>Продолжительность</th>
                                    <th>Описание</th>
                                    <th>Действия</th>
                                </tr>
HTML
    
    foreach my $program (@$programs) {
        my $id = $program->{id};
        my $name = $program->{name};
        my $category_id = $program->{category_id};
        my $duration = $program->{duration};
        my $description = $program->{description};
        
        # Получаем название категории
        my $category_name = "Неизвестно";
        foreach my $category (@$categories) {
            if ($category->{id} == $category_id) {
                $category_name = $category->{name};
                last;
            }
        }
        
        print <<HTML;
                                <tr>
                                    <td>$id</td>
                                    <td>$name</td>
                                    <td>$category_name</td>
                                    <td>$duration мин.</td>
                                    <td>$description</td>
                                    <td>
                                        <button onclick="confirmDelete('program', $id, '$name')" class="btn secondary">Удалить</button>
                                    </td>
                                </tr>
HTML
    }
    
    print <<HTML;
                            </table>
                        </div>
                        
                        <!-- Вкладка Расписание -->
                        <div id="schedule-tab" class="tab-content" style="display: none;">
                            <h3>Добавить запись в расписание</h3>
                            <form action="/cgi-bin/admin.pl" method="get" class="admin-form">
                                <input type="hidden" name="action" value="add_schedule">
                                <div class="form-group">
                                    <label for="schedule-channel">Канал:</label>
                                    <select id="schedule-channel" name="channel_id" required>
                                        <option value="">Выберите канал</option>
HTML
    
    foreach my $channel (@$channels) {
        my $id = $channel->{id};
        my $name = $channel->{name};
        
        print qq(<option value="$id">$name</option>\n);
    }
    
    print <<HTML;
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label for="schedule-program">Программа:</label>
                                    <select id="schedule-program" name="program_id" required>
                                        <option value="">Выберите программу</option>
HTML
    
    foreach my $program (@$programs) {
        my $id = $program->{id};
        my $name = $program->{name};
        
        print qq(<option value="$id">$name</option>\n);
    }
    
    print <<HTML;
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label for="schedule-date">Дата:</label>
                                    <input type="date" id="schedule-date" name="date" value="$date" required>
                                </div>
                                <div class="form-group">
                                    <label for="schedule-start">Время начала:</label>
                                    <input type="time" id="schedule-start" name="start_time" required>
                                </div>
                                <div class="form-group">
                                    <label for="schedule-end">Время окончания:</label>
                                    <input type="time" id="schedule-end" name="end_time" required>
                                </div>
                                <button type="submit" class="btn primary">Добавить в расписание</button>
                            </form>
                            
                            <h3>Расписание</h3>
                            <table>
                                <tr>
                                    <th>ID</th>
                                    <th>Канал</th>
                                    <th>Программа</th>
                                    <th>Дата</th>
                                    <th>Начало</th>
                                    <th>Окончание</th>
                                    <th>Действия</th>
                                </tr>
HTML
    
    foreach my $item (@$schedule) {
        my $id = $item->{id};
        my $channel_id = $item->{channel_id};
        my $program_id = $item->{program_id};
        my $date = $item->{date};
        my $start_time = $item->{start_time};
        my $end_time = $item->{end_time};
        
        # Получаем название канала
        my $channel_name = "Неизвестно";
        foreach my $channel (@$channels) {
            if ($channel->{id} == $channel_id) {
                $channel_name = $channel->{name};
                last;
            }
        }
        
        # Получаем название программы
        my $program_name = "Неизвестно";
        foreach my $program (@$programs) {
            if ($program->{id} == $program_id) {
                $program_name = $program->{name};
                last;
            }
        }
        
        print <<HTML;
                                <tr>
                                    <td>$id</td>
                                    <td>$channel_name</td>
                                    <td>$program_name</td>
                                    <td>$date</td>
                                    <td>$start_time</td>
                                    <td>$end_time</td>
                                    <td>
                                        <button onclick="confirmDelete('schedule', $id, '$program_name')" class="btn secondary">Удалить</button>
                                    </td>
                                </tr>
HTML
    }
    
    print <<HTML;
                            </table>
                        </div>
                    </div>
                </div>
            </section>
        </main>
HTML

    print Common::html_footer();
}

# Запускаем основную функцию
eval {
    display_admin();
};

if ($@) {
    print "<h2>Произошла ошибка:</h2><pre>$@</pre>";
}