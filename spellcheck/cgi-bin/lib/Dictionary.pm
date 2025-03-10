package Dictionary;

use strict;
use warnings;
use utf8;
use DB_File;
use Fcntl qw(:DEFAULT);
use Encode qw(decode encode);

sub new {
    my ($class, $dict_file) = @_;
    $dict_file ||= "../data/dictionary.db";
    
    my $self = {
        dict_file => $dict_file,
        dict => {},
    };
    
    bless $self, $class;
    $self->_init();
    return $self;
}

sub _init {
    my ($self) = @_;
    
    unless (-e $self->{dict_file}) {
        my %dict;
        tie %dict, 'DB_File', $self->{dict_file}, O_CREAT|O_RDWR, 0644, $DB_HASH
            or die "Не удалось создать словарь: $!";
        
        foreach my $word (qw(привет мир компьютер программа словарь текст проверка)) {
            $word = encode('UTF-8', $word) if Encode::is_utf8($word);
            $dict{$word} = 1;
        }
        untie %dict;
    }
    
    # Открываем словарь
    tie %{$self->{dict}}, 'DB_File', $self->{dict_file}, O_RDWR, 0644, $DB_HASH
        or die "Не удалось открыть словарь: $!";
}

sub exists {
    my ($self, $word) = @_;
    $word = lc($word);
    $word = encode('UTF-8', $word) if Encode::is_utf8($word);
    return exists $self->{dict}{lc($word)};
}

sub add_word {
    my ($self, $word) = @_;
    $word = lc($word);
    $word = encode('UTF-8', $word) if Encode::is_utf8($word);
    $self->{dict}{$word} = 1;
    return 1;
}

sub delete_word {
    my ($self, $word) = @_;
    $word = lc($word);
    $word = encode('UTF-8', $word) if Encode::is_utf8($word);
    if (exists $self->{dict}{$word}) {
        delete $self->{dict}{$word};
        return 1;
    }
    return 0;
}

sub edit_word {
    my ($self, $old_word, $new_word) = @_;
    $old_word = lc($old_word);
    $new_word = lc($new_word);
    $old_word = encode('UTF-8', $old_word) if Encode::is_utf8($old_word);
    $new_word = encode('UTF-8', $new_word) if Encode::is_utf8($new_word);
    
    if (exists $self->{dict}{$old_word}) {
        delete $self->{dict}{$old_word};
        $self->{dict}{$new_word} = 1;
        return 1;
    }
    return 0;
}

sub get_all_words {
    my ($self) = @_;
    my @words;
    foreach my $word (sort keys %{$self->{dict}}) {
        push @words, decode('UTF-8', $word) unless Encode::is_utf8($word);
    }
    return @words;
}

sub find_similar {
    my ($self, $word, $threshold) = @_;
    $threshold ||= 0.8; # По умолчанию 80% схожести
    $word = lc($word);
    
    my @similar_words;
    foreach my $dict_word (keys %{$self->{dict}}) {
        my $similarity = $self->calculate_similarity($word, $dict_word);
        if ($similarity >= $threshold) {
            push @similar_words, { word => $dict_word, similarity => $similarity };
        }
    }
    
    # Сортируем по убыванию схожести
    @similar_words = sort { $b->{similarity} <=> $a->{similarity} } @similar_words;
    
    return @similar_words;
}

sub calculate_similarity {
    my ($self, $word1, $word2) = @_;
    
    # Используем расстояние Левенштейна для определения схожести
    my $distance = $self->levenshtein_distance($word1, $word2);
    my $max_length = length($word1) > length($word2) ? length($word1) : length($word2);
    
    # Преобразуем расстояние в процент схожести
    my $similarity = 1 - ($distance / $max_length);
    
    return $similarity;
}

sub levenshtein_distance {
    my ($self, $s, $t) = @_;
    
    my @s = split //, $s;
    my @t = split //, $t;
    
    my @d;
    $d[0][0] = 0;
    
    for my $i (1 .. scalar @s) {
        $d[$i][0] = $i;
    }
    
    for my $j (1 .. scalar @t) {
        $d[0][$j] = $j;
    }
    
    for my $j (1 .. scalar @t) {
        for my $i (1 .. scalar @s) {
            my $cost = $s[$i-1] eq $t[$j-1] ? 0 : 1;
            $d[$i][$j] = min(
                $d[$i-1][$j] + 1,      # удаление
                $d[$i][$j-1] + 1,      # вставка
                $d[$i-1][$j-1] + $cost # замена
            );
        }
    }
    
    return $d[scalar @s][scalar @t];
}

sub min {
    my ($a, $b, $c) = @_;
    return $a < $b ? ($a < $c ? $a : $c) : ($b < $c ? $b : $c);
}

sub DESTROY {
    my ($self) = @_;
    untie %{$self->{dict}} if tied %{$self->{dict}};
}

1; 