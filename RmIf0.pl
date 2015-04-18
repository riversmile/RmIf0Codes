#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: RmIf0.pl
#
#        USAGE: RmIf0 dir_name 
#
#  DESCRIPTION: remove the '#if 0' code blocks in C/C++ files
#       AUTHOR: CHEN JIA(report bugs to chen.td.jia@gmail.com)
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2015/4/1 18:59:24
#     REVISION: ---
#      LICENSE: This program is free software; you can redistribute it and/or
#               modify it under the same terms as Perl itself.
#===============================================================================

use File::chdir::WalkDir;
use File::Copy "cp";

if ( not -d $ARGV[0] ) {
    printf "$ARGV[0] is not a valid directory, please input absolute path correctly!\n";
    exit(0);
}	

#only *.c, *.h or *.cpp, *.hpp, *.inc files to be processed
my $file_type = qr/\.(c|cpp|h|hpp|inc)$/;
my $rm_enter = qr/^\s*\#if\s+0/;
my $kp_enter = qr/^\s*\#if\s+1/;
my $if_enter = qr/^\s*\#(ifdef|ifndef|if)/;
my $else_enter = qr/^\s*\#(else|elif)/;
my $level_exit = qr/^\s*\#endif/;
my $bkup_postfix = ".rmbak";

my $remove_func = sub {
    my ($filename, $dirname) = @_ ;
    my $out_file = 'tmp';
    my $rm_cnt = 0;
    my @mode_stack = ();#0:Del Mode, 1:Keep Mode, 2:Other if Mode
    my $NotDelMode = sub{ !(grep {0 == $_} @mode_stack) };

    return unless $filename =~ $file_type;

    open IN , '<', $filename or die "Can not open file $filename: $!\n";
    open OUT , '>', $out_file or die "Can not open file $out_file: $!\n";
    while(<IN>){
        chomp;
        if(/$rm_enter/){
            push @mode_stack, 0;
            cp($filename, $filename.$bkup_postfix) if (not -f $filename.$bkup_postfix);
        }
        elsif(/$kp_enter/){
            push @mode_stack, 1;
        }
        elsif(/$if_enter/){
            push @mode_stack, 2;
            print OUT $_."\n" if &$NotDelMode;
        }
        elsif(/$else_enter/){
            if(2 == $mode_stack[-1]){
                print OUT $_."\n" if &$NotDelMode;
                next;
            }
            $mode_stack[-1] = ($mode_stack[-1] == 0) ? 1 : 0;
        }
        elsif(/$level_exit/){
            if(2 == $mode_stack[-1]){
                print OUT $_."\n" if &$NotDelMode;
                pop @mode_stack;
                next;
            }
            pop @mode_stack if scalar(@mode_stack);
            $rm_cnt++ if !scalar(@mode_stack);
        }
        else{
            print OUT $_."\n" if &$NotDelMode;
        };
                       
    }
    close IN;
    close OUT;

    unlink $filename;
    rename $out_file, $filename;

    unlink $filename.$bkup_postfix if !$rm_cnt;
    printf "$rm_cnt '#if 0' segment(s) or '#if 1' line(s) removed in $filename!\n" if $rm_cnt;
};

walkdir($ARGV[0], $remove_func);

__END__
