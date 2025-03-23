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
my $channel_id = $q->param('channel') || '';
my $date = $q->param('date') || strftime("%Y-%m-%d", localtime);
my $category_id = $q->param('category') || '';
my $time_from = $q->param('time_from') || '';
my $time_to = $q->param('time_to') || '';

# Функция для получения информации о канале
sub get_channel {
    my ($id) = @_;
    my %channels;
    my $channel;
    
    tie %channels, 'DB_File', $Common::channels_db, O_RDONLY, 0666, $DB_HASH
        or die "Не удалось открыть $Common::channels_db: $!";
    
    if (exists $channels{$id}) {
        my $data = Encode::decode('UTF-8', $channels{$id});
        $channel = Common::decode_json($data);
        $channel->{id} = $id;
    }
    
    untie %channels;
    
    return $channel;
}

# Функция для получения информации о категории
sub get_category {
    my ($id) = @_;
    my %categories;
    my $category;
    
    tie %categories, 'DB_File', $Common::categories_db, O_RDONLY, 0666, $DB_HASH
        or die "Не удалось открыть $Common::categories_db: $!";
    
    if (exists $categories{$id}) {
        my $data = Encode::decode('UTF-8', $categories{$id});
        $category = Common::decode_json($data);
        $category->{id} = $id;
    }
    
    untie %categories;
    
    return $category;
}

# Функция для получения информации о программе
sub get_program {
    my ($id) = @_;
    my %programs;
    my $program;
    
    tie %programs, 'DB_File', $Common::programs_db, O_RDONLY, 0666, $DB_HASH
        or die "Не удалось открыть $Common::programs_db: $!";
    
    if (exists $programs{$id}) {
        my $data = Encode::decode('UTF-8', $programs{$id});
        $program = Common::decode_json($data);
        $program->{id} = $id;
    }
    
    untie %programs;
    
    return $program;
}

# Функция для получения расписания
sub get_schedule {
    my ($channel_id, $date, $category_id, $time_from, $time_to) = @_;
    my %schedule;
    my @schedule_list;
    
    tie %schedule, 'DB_File', $Common::schedule_db, O_RDONLY, 0666, $DB_HASH
        or die "Не удалось открыть $Common::schedule_db: $!";
    
    foreach my $id (keys %schedule) {
        my $data = Encode::decode('UTF-8', $schedule{$id});
        my $item = Common::decode_json($data);
        $item->{id} = $id;
        
        # Фильтрация по каналу
        next if $channel_id && $item->{channel_id} != $channel_id;
        
        # Фильтрация по дате
        next if $date && $item->{date} ne $date;
        
        # Получаем информацию о программе
        my $program = get_program($item->{program_id});
        next unless $program;
        
        # Фильтрация по категории
        next if $category_id && $program->{category_id} != $category_id;
        
        # Фильтрация по времени начала
        next if $time_from && $item->{start_time} lt $time_from;
        
        # Фильтрация по времени окончания
        next if $time_to && $item->{end_time} gt $time_to;
        
        # Добавляем информацию о программе и категории
        $item->{program} = $program;
        $item->{category} = get_category($program->{category_id});
        
        push @schedule_list, $item;
    }
    
    untie %schedule;
    
    # Сортировка по времени начала
    @schedule_list = sort { $a->{start_time} cmp $b->{start_time} } @schedule_list;
    
    return \@schedule_list;
}

# Функция для отображения программы передач
sub display_programs {
    Common::ensure_db_exists();
    
    my $selected_channel = $channel_id ? get_channel($channel_id) : undef;
    my $selected_category = $category_id ? get_category($category_id) : undef;
    my $schedule = get_schedule($channel_id, $date, $category_id, $time_from, $time_to);
    my $channels = Common::get_all_channels();
    my $categories = get_all_categories();
    
    print Common::html_header("Программа передач", "programs");
    
    print <<HTML;
        <main>
            <section>
                <h2>Программа передач</h2>
                
                <div class="filter-form">
                    <form action="/cgi-bin/programs.pl" method="get" id="filter-form">
                        <div class="form-row">
                            <div class="form-group">
                                <label for="channel">Канал:</label>
                                <select id="channel" name="channel">
                                    <option value="">Все каналы</option>
HTML
    
    foreach my $channel (@$channels) {
        my $id = $channel->{id};
        my $name = $channel->{name};
        my $selected = $channel_id && $channel_id == $id ? 'selected' : '';
        
        print qq(<option value="$id" $selected>$name</option>\n);
    }
    
    print <<HTML;
                                </select>
                            </div>
                            <div class="form-group">
                                <label for="date">Дата:</label>
                                <input type="date" id="date" name="date" value="$date">
                            </div>
                            <div class="form-group">
                                <label for="category">Категория:</label>
                                <select id="category" name="category">
                                    <option value="">Все категории</option>
HTML
    
    foreach my $category (@$categories) {
        my $id = $category->{id};
        my $name = $category->{name};
        my $selected = $category_id && $category_id == $id ? 'selected' : '';
        
        print qq(<option value="$id" $selected>$name</option>\n);
    }
    
    print <<HTML;
                                </select>
                            </div>
                            <div class="form-group">
                                <label for="time-from">Время от:</label>
                                <input type="time" id="time-from" name="time_from" value="$time_from">
                            </div>
                            <div class="form-group">
                                <label for="time-to">Время до:</label>
                                <input type="time" id="time-to" name="time_to" value="$time_to">
                            </div>
                        </div>
                        <div class="form-row">
                            <div class="form-group" style="flex: 0 0 auto; margin-left: auto;">
                                <button type="submit" class="btn primary">Применить фильтры</button>
                                <a href="/cgi-bin/programs.pl" class="btn secondary">Сбросить</a>
                            </div>
                        </div>
                    </form>
                </div>
                
                <div class="program-list">
HTML
    
    if ($selected_channel) {
        print <<HTML;
                    <div class="selected-channel">
                        <img src="$selected_channel->{logo}" alt="$selected_channel->{name}">
                        <h3>$selected_channel->{name}</h3>
                        <p>$selected_channel->{description}</p>
                    </div>
HTML
    }
    
    if ($selected_category) {
        print <<HTML;
                    <div class="selected-category">
                        <img src="$selected_category->{icon}" alt="$selected_category->{name}">
                        <h3>Категория: $selected_category->{name}</h3>
                        <p>$selected_category->{description}</p>
                    </div>
HTML
    }
    
    if (@$schedule) {
        my $current_channel_id = '';
        
        foreach my $item (@$schedule) {
            my $channel = get_channel($item->{channel_id});
            
            # Если не выбран конкретный канал, добавляем заголовок для каждого канала
            if (!$channel_id && $current_channel_id ne $item->{channel_id}) {
                $current_channel_id = $item->{channel_id};
                
                print <<HTML;
                    <div class="channel-header">
                        <img src="$channel->{logo}" alt="$channel->{name}">
                        <h3>$channel->{name}</h3>
                    </div>
HTML
            }
            
            my $program = $item->{program};
            my $category = $item->{category};
            
            print <<HTML;
                    <div class="program-card">
                        <div class="program-time">
                            <span>$item->{start_time}</span>
                            <span>$item->{end_time}</span>
                        </div>
                        <div class="program-info">
                            <h3 class="program-title">$program->{name}</h3>
                            <span class="program-category">$category->{name}</span>
                            <p class="program-description">$program->{description}</p>
                            <p class="program-duration">Продолжительность: $program->{duration} мин.</p>
                        </div>
                    </div>
HTML
        }
    } else {
        print <<HTML;
                    <div class="no-results">
                        <p>Программы не найдены. Попробуйте изменить параметры фильтрации.</p>
                    </div>
HTML
    }
    
    print <<HTML;
                </div>
            </section>
        </main>
HTML

    print Common::html_footer();
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

# Запускаем основную функцию
eval {
    display_programs();
};

if ($@) {
    print "<h2>Произошла ошибка:</h2><pre>$@</pre>";
} 