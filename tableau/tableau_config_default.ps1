$tableau_dump_folder="c:\ms_backup\tableau\dumps"
$tableau_dump_folder_last="c:\ms_backup\tableau\dumps\last"
$tableau_user="administrator"
$tableau_pwd="password,"


$diff_files_locations += new-wbfilespec $tableau_dump_folder

$rotate_dirs+=$tableau_dump_folder