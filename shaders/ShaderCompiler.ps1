# credit: IA team
$ROOT = "C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Mod Tools\mod_tools"
$COMPILER_PATH = $ROOT + "\tools\bin\ShaderCompiler.exe"
$INPUT_PATH = $ROOT + "\shader\shader_input"
$OUTPUT_PATH = "D:\SteamLibrary\steamapps\common\Don't Starve Together\mods\UncompromisingMode\shaders"

$shader_name = Read-Host Prompt "Shader Name:"
$vs_shader_path = $INPUT_PATH + "\" + $shader_name + ".vs"

$ps_shader_path = $INPUT_PATH + "\" + $shader_name + ".ps"
$ksh_shader_path = $OUTPUT_PATH + "\" + $shader_name + ".ksh"
& $COMPILER_PATH -little $shader_name $vs_shader_path $ps_shader_path $ksh_shader_path -oglsl