# credit: IA team
$ROOT = "C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Mod Tools\mod_tools\tools\bin"
$COMPILER_PATH = $ROOT + "\ShaderCompiler.exe"

$shader_name = Read-Host Prompt "Shader Name:"c:\Users\marth\OneDrive\Área de Trabalho\lavamolten(4)\lavamolten.textil
$vs_shader_path = $ROOT + "\shader_input\" + $shader_name + ".vs"

$ps_shader_path = $ROOT + "\shader_input\" + $shader_name + ".ps"
$ksh_shader_path = $ROOT + "\shader_output\" + $shader_name + ".ksh"
& $COMPILER_PATH -little $shader_name $vs_shader_path $ps_shader_path $ksh_shader_path -oglsl