#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
use lib dirname(__FILE__);
use Common;

# Включаем вывод ошибок в браузер
BEGIN {
    $ENV{PERL_CGI_STDERR_TO_BROWSER} = 1;
}

binmode(STDOUT, ":utf8");
print "Content-type: text/html; charset=utf-8\n\n";

my $q = CGI->new;
my $search = $q->param('search') || '';
$search = Encode::decode('UTF-8', $search) unless Encode::is_utf8($search);

# Основная функция для отображения списка каналов
sub display_channels {
    Common::ensure_db_exists();
    my $channels = Common::get_all_channels($search);
    
    print Common::html_header("Телеканалы", "channels");
    
    print <<HTML;
        <main>
            <section>
                <h2>Телеканалы</h2>
                
                <div class="filter-form">
                    <form action="/cgi-bin/channels.pl" method="get">
                        <div class="form-row">
                            <div class="form-group">
                                <label for="search">Поиск канала:</label>
                                <input type="text" id="search" name="search" value="$search" placeholder="Введите название канала...">
                            </div>
                            <div class="form-group" style="flex: 0 0 auto; align-self: flex-end;">
                                <button type="submit" class="btn primary">Найти</button>
                                <a href="/cgi-bin/channels.pl" class="btn secondary">Сбросить</a>
                            </div>
                        </div>
                    </form>
                </div>
                
                <div class="channel-list">
HTML
    
    if (@$channels) {
        print "<div class=\"channel-grid\">\n";
        
        foreach my $channel (@$channels) {
            my $id = $channel->{id};
            my $name = $channel->{name};
            my $logo = $channel->{logo};
            my $description = $channel->{description};
            
            print <<HTML;
                    <div class="channel-card">
                        <img src="$logo" alt="$name">
                        <h3>$name</h3>
                        <p>$description</p>
                        <a href="/cgi-bin/programs.pl?channel=$id" class="btn primary">Программа передач</a>
                    </div>
HTML
        }
        
        print "</div>\n";
    } else {
        print <<HTML;
                    <div class="no-results">
                        <p>Каналы не найдены. Попробуйте изменить параметры поиска.</p>
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

# Запускаем основную функцию
eval {
    display_channels();
};

if ($@) {
    print "<h2>Произошла ошибка:</h2><pre>$@</pre>";
} 