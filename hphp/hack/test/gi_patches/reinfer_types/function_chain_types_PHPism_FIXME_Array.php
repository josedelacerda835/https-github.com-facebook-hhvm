//// file1.php
<?hh

/* HH_FIXME[2071] Fixme'd to not have thousands of FIXMEs in WWW (for now) */
 type PHPism_FIXME_Array = varray_or_darray;

//// file2.php
<?hh

function fa(PHPism_FIXME_Array $x) {
  return $x;
}

//// file3.php
<?hh

function fb(): PHPism_FIXME_Array {
  return darray[4 => "why type?"];
}

function foo(): void {
  fa(fb());
}
