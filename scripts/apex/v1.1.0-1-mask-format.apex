// v1.1.0 Test 1 – Masking format. READ-ONLY: no data is created or changed.
// Uses made-up test numbers only. Run: Developer Console > Debug > Open Execute Anonymous Window,
// tick "Open Log", Execute, then tick "Debug Only".

Map<String, String> expected = new Map<String, String>{
    '9876543221'      => '98XXXXXX21',
    '919876543221'    => '98XXXXXX21',
    '+91 98765-43221' => '98XXXXXX21',
    '00919876543221'  => '98XXXXXX21',
    '09876543221'     => '98XXXXXX21',
    '+971501234567'   => '97XXXXXXXX67',
    '12345'           => '12X45',
    '1234'            => 'XXXX',
    ''                => '',
    'no digits'       => ''
};

Integer passed = 0;
Integer failed = 0;
for (String input : expected.keySet()) {
    String actual = PhoneMaskUtil.mask(input);
    Boolean ok = actual == expected.get(input);
    if (ok) { passed++; } else { failed++; }
    System.debug((ok ? 'PASS' : 'FAIL') + ' | input "' + input + '" => "' + actual + '" (expected "' + expected.get(input) + '")');
}

System.debug((PhoneMaskUtil.mask(null) == null ? 'PASS' : 'FAIL') + ' | null stays null');

String text = 'Call 9876543221 or +91 91234 56780 today, visit on 2026-10-05';
String maskedText = PhoneMaskUtil.maskInText(text);
Boolean textOk = maskedText == 'Call 98XXXXXX21 or 91XXXXXX80 today, visit on 2026-10-05';
if (textOk) { passed++; } else { failed++; }
System.debug((textOk ? 'PASS' : 'FAIL') + ' | free text => ' + maskedText);

System.debug('RESULT: ' + passed + ' passed, ' + failed + ' failed');
