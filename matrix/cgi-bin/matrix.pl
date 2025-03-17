#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use JSON;
use lib '.';
use Matrix;

my $cgi = CGI->new;
print $cgi->header(-type => 'application/json', -charset => 'utf-8');

# Получение параметров запроса
my $action = $cgi->param('action') || '';
my $response = { success => 1, message => '', data => {} };

eval {
    if ($action eq 'create') {
        # Создание матрицы
        my $rows = $cgi->param('rows') || 3;
        my $cols = $cgi->param('cols') || 3;
        my $fill_type = $cgi->param('fill_type') || 'zeros';
        
        # Проверка ограничений на размер
        if ($rows > 10 || $cols > 10) {
            die "Максимальный размер матрицы: 10x10";
        }
        
        my $matrix = Matrix->new($rows, $cols);
        
        if ($fill_type eq 'random') {
            $matrix->fill_random();
        } elsif ($fill_type eq 'manual') {
            for my $i (0..$rows-1) {
                for my $j (0..$cols-1) {
                    my $value = $cgi->param("cell_${i}_${j}") || 0;
                    $matrix->set($i, $j, $value);
                }
            }
        }
        
        # Сохраняем матрицу в формате JSON для передачи клиенту
        my @matrix_data;
        for my $i (0..$rows-1) {
            my @row;
            for my $j (0..$cols-1) {
                push @row, $matrix->get($i, $j);
            }
            push @matrix_data, \@row;
        }
        
        $response->{data} = {
            matrix => \@matrix_data,
            html => $matrix->to_html()
        };
    }
    elsif ($action eq 'transpose') {
        # Транспонирование матрицы
        my $matrix_data = decode_json($cgi->param('matrix') || '[]');
        my $rows = scalar @$matrix_data;
        my $cols = scalar @{$matrix_data->[0]} if $rows > 0;
        
        my $matrix = Matrix->new($rows, $cols);
        for my $i (0..$rows-1) {
            for my $j (0..$cols-1) {
                $matrix->set($i, $j, $matrix_data->[$i][$j]);
            }
        }
        
        my $result = $matrix->transpose();
        
        # Сохраняем результат
        my @result_data;
        for my $i (0..$result->{rows}-1) {
            my @row;
            for my $j (0..$result->{cols}-1) {
                push @row, $result->get($i, $j);
            }
            push @result_data, \@row;
        }
        
        $response->{data} = {
            matrix => \@result_data,
            html => $result->to_html()
        };
    }
    elsif ($action eq 'min_max') {
        # Поиск минимального и максимального элементов
        my $matrix_data = decode_json($cgi->param('matrix') || '[]');
        my $rows = scalar @$matrix_data;
        my $cols = scalar @{$matrix_data->[0]} if $rows > 0;
        
        my $matrix = Matrix->new($rows, $cols);
        for my $i (0..$rows-1) {
            for my $j (0..$cols-1) {
                $matrix->set($i, $j, $matrix_data->[$i][$j]);
            }
        }
        
        my $min = $matrix->min();
        my $max = $matrix->max();
        
        $response->{data} = {
            min => $min,
            max => $max
        };
    }
    elsif ($action eq 'add') {
        # Сложение матриц
        my $matrix1_data = decode_json($cgi->param('matrix1') || '[]');
        my $matrix2_data = decode_json($cgi->param('matrix2') || '[]');
        
        my $rows1 = scalar @$matrix1_data;
        my $cols1 = scalar @{$matrix1_data->[0]} if $rows1 > 0;
        
        my $rows2 = scalar @$matrix2_data;
        my $cols2 = scalar @{$matrix2_data->[0]} if $rows2 > 0;
        
        # Проверка размерностей
        if ($rows1 != $rows2 || $cols1 != $cols2) {
            die "Невозможно сложить матрицы разных размеров";
        }
        
        my $matrix1 = Matrix->new($rows1, $cols1);
        for my $i (0..$rows1-1) {
            for my $j (0..$cols1-1) {
                $matrix1->set($i, $j, $matrix1_data->[$i][$j]);
            }
        }
        
        my $matrix2 = Matrix->new($rows2, $cols2);
        for my $i (0..$rows2-1) {
            for my $j (0..$cols2-1) {
                $matrix2->set($i, $j, $matrix2_data->[$i][$j]);
            }
        }
        
        my $result = $matrix1->add($matrix2);
        
        # Сохраняем результат
        my @result_data;
        for my $i (0..$result->{rows}-1) {
            my @row;
            for my $j (0..$result->{cols}-1) {
                push @row, $result->get($i, $j);
            }
            push @result_data, \@row;
        }
        
        $response->{data} = {
            matrix => \@result_data,
            html => $result->to_html()
        };
    }
    elsif ($action eq 'multiply') {
        # Умножение матриц
        my $matrix1_data = decode_json($cgi->param('matrix1') || '[]');
        my $matrix2_data = decode_json($cgi->param('matrix2') || '[]');
        
        my $rows1 = scalar @$matrix1_data;
        my $cols1 = scalar @{$matrix1_data->[0]} if $rows1 > 0;
        
        my $rows2 = scalar @$matrix2_data;
        my $cols2 = scalar @{$matrix2_data->[0]} if $rows2 > 0;
        
        # Проверка размерностей
        if ($cols1 != $rows2) {
            die "Невозможно умножить матрицы: количество столбцов первой матрицы должно быть равно количеству строк второй матрицы";
        }
        
        my $matrix1 = Matrix->new($rows1, $cols1);
        for my $i (0..$rows1-1) {
            for my $j (0..$cols1-1) {
                $matrix1->set($i, $j, $matrix1_data->[$i][$j]);
            }
        }
        
        my $matrix2 = Matrix->new($rows2, $cols2);
        for my $i (0..$rows2-1) {
            for my $j (0..$cols2-1) {
                $matrix2->set($i, $j, $matrix2_data->[$i][$j]);
            }
        }
        
        my $result = $matrix1->multiply($matrix2);
        
        # Сохраняем результат
        my @result_data;
        for my $i (0..$result->{rows}-1) {
            my @row;
            for my $j (0..$result->{cols}-1) {
                push @row, $result->get($i, $j);
            }
            push @result_data, \@row;
        }
        
        $response->{data} = {
            matrix => \@result_data,
            html => $result->to_html()
        };
    }
    elsif ($action eq 'inverse') {
        # Вычисление обратной матрицы
        my $matrix_data = decode_json($cgi->param('matrix') || '[]');
        my $rows = scalar @$matrix_data;
        my $cols = scalar @{$matrix_data->[0]} if $rows > 0;
        
        # Проверка, что матрица квадратная
        if ($rows != $cols) {
            die "Обратную матрицу можно вычислить только для квадратной матрицы";
        }
        
        my $matrix = Matrix->new($rows, $cols);
        for my $i (0..$rows-1) {
            for my $j (0..$cols-1) {
                $matrix->set($i, $j, $matrix_data->[$i][$j]);
            }
        }
        
        my $result = $matrix->inverse();
        
        # Сохраняем результат
        my @result_data;
        for my $i (0..$result->{rows}-1) {
            my @row;
            for my $j (0..$result->{cols}-1) {
                push @row, $result->get($i, $j);
            }
            push @result_data, \@row;
        }
        
        $response->{data} = {
            matrix => \@result_data,
            html => $result->to_html()
        };
    }
    else {
        die "Неизвестное действие: $action";
    }
};

if ($@) {
    $response->{success} = 0;
    $response->{message} = $@;
}

print to_json($response); 