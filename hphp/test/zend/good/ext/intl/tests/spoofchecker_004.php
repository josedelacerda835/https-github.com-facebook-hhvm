<?hh
<<__EntryPoint>> function main(): void {
$korean = "\xED\x95\x9C" . "\xEA\xB5\xAD" . "\xEB\xA7\x90";

$issues = 0;
$x = new SpoofChecker();
echo "Check with default settings\n";
var_dump($x->areConfusable("HELLO", "H\xD0\x95LLO", inout $issues));
var_dump($x->areConfusable("hello", "h\xD0\xB5llo", inout $issues));

echo "Change confusable settings\n";
$x->setChecks(SpoofChecker::MIXED_SCRIPT_CONFUSABLE |
  SpoofChecker::WHOLE_SCRIPT_CONFUSABLE |
  SpoofChecker::SINGLE_SCRIPT_CONFUSABLE);
var_dump($x->areConfusable("HELLO", "H\xD0\x95LLO", inout $issues));
var_dump($x->areConfusable("hello", "h\xD0\xB5llo", inout $issues));
}
