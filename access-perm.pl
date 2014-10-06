#!/usr/bin/perl
use utf8;
use open ':utf8';

open $stdout, ">", "/tmp/access.sh";
print $stdout "#!/bin/sh\n";

sub set_command {
  print $stdout shift;
#  print shift;
}

sub set_perm {
  printf $stdout "setfacl -R -d -m \"u:%s:%sx\" \"$perm_path\"\n",@_;
  printf $stdout "setfacl -R    -m  \"u:%s:%sx\" \"$perm_path\"\n",@_;
#  printf "setfacl -R -d -m  \"u:%s:%sx\" \"$perm_path\"\n",@_;
#  printf "setfacl -R    -m  \"u:%s:%sx\" \"$perm_path\"\n",@_;
};

sub remove_perm {
   printf $stdout "setfacl -R -d -x  \"u:%s\" \"$perm_path\"\n",@_;
   printf $stdout "setfacl -R    -x  \"u:%s\" \"$perm_path\"\n",@_;
#   printf "setfacl -R -d -x  \"u:%s\" \"$perm_path\"\n",@_;
#   printf "setfacl -R    -x  \"u:%s\" \"$perm_path\"\n",@_;
}

open CSV, "dserver_access.csv";
$perm_path="%s";
while (<CSV>) {
  @{$dserver[$max_lines]}=split '\|';
  chomp(${$dserver[$max_lines]}[-1]);
  $max_lines++;
}
close CSV;

$first_row=0;
while (1) {
  last if ${$dserver[$first_row]}[1];
  $first_row++;
  $perm_path="$perm_path/%s";
}
$end_row=$max_lines-1;

$first_column=0;
$name_column=0;
while (1) {
  last if ${$dserver[0]}[$first_column];
  $name_column++ unless ${$dserver[$first_row]}[$first_column];
  $first_column++;
}
$end_column=$#{$dserver[$max_lines-1]}-1;

for ($first_row..$end_row) { $name[$_] = ${$dserver[$_]}[1]; }

for $column ($first_column..$end_column) {
  for (0..($first_row-1)){

    if (${$dserver[$_]}[$column]) {
      $main_row=$_;
      $column_of_row[$_]=$column;
      for ($_..($first_row-2)){
        $column_of_row[$_+1]=undef;
      }
    }
  }

sub array_dirs {
    my @array;
    for $i ( 0..($max_lines) ) {
        push @array, ${$dserver[$i]}[$column_of_row[$i]];
    }
    @array;
};

  for $row ($first_row..$end_row) {
    if (${$dserver[$row]}[$column]) {
    &set_perm (
      $name[$row],
      ${$dserver[$row]}[$column],
      &array_dirs()
    ) } else {
          &remove_perm (
            $name[$row],
            &array_dirs()
          )
        }

# добавляем rx на каталоги выше

    if ($column_of_row[3]) {
      if (${$dserver[$row]}[$column] ne "") {
        if (${$dserver[$row]}[$column_of_row[2]] eq "") {
          &set_command ("setfacl -m \"u:${$dserver[$row]}[$name_column]:rx\" \"${$dserver[0]}[$column_of_row[0]]/${$dserver[1]}[$column_of_row[1]]/${$dserver[2]}[$column_of_row[2]]\"\n");
        }
        if (${$dserver[$row]}[$column_of_row[1]] eq "") {
          &set_command ("setfacl -m \"u:${$dserver[$row]}[$name_column]:rx\" \"${$dserver[0]}[$column_of_row[0]]/${$dserver[1]}[$column_of_row[1]]\"\n");
        }
        if (${$dserver[$row]}[$column_of_row[0]] eq "") {
          &set_command ("setfacl -m \"u:${$dserver[$row]}[$name_column]:rx\" \"${$dserver[0]}[$column_of_row[0]]\"\n");
        }
      }
    }
    
    elsif ($column_of_row[2]) {
      if (${$dserver[$row]}[$column] ne "") {
        if (${$dserver[$row]}[$column_of_row[1]] eq "") {
          &set_command ("setfacl -m \"u:${$dserver[$row]}[$name_column]:rx\" \"${$dserver[0]}[$column_of_row[0]]/${$dserver[1]}[$column_of_row[1]]\"\n");
        }
        if (${$dserver[$row]}[$column_of_row[0]] eq "") {
          &set_command ("setfacl -m \"u:${$dserver[$row]}[$name_column]:rx\" \"${$dserver[0]}[$column_of_row[0]]\"\n");
        }
     }
    }

    elsif ($column_of_row[1]) {
      if (${$dserver[$row]}[$column] ne "") {
        if (${$dserver[$row]}[$column_of_row[0]] eq "") {
          &set_command ("setfacl -m \"u:${$dserver[$row]}[$name_column]:rx\" \"${$dserver[0]}[$column_of_row[0]]\"\n");
        }
      }
    }


  }
}

set_command "cd prj\n";
set_command "./update-perm.sh\n";
set_command "cd ..\n";

close $stdout;
#system ("scp /tmp/access.sh root\@10.10.10.90:/home/FldDir/");
