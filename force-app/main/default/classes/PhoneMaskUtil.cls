/**
 * @description Single place that masks customer phone numbers, e.g. 9876543221 => 98XXXXXX21.
 *              The format (visible digits, mask character, country code) comes from
 *              Phone_Masking_Setting__mdt through PhoneMaskingConfig.
 *              Pure string logic: no SOQL, no DML.
 * @group       Phone Masking
 */
public inherited sharing class PhoneMaskUtil {
    // A run of digits, optionally starting with '+', that may contain spaces or hyphens.
    // Runs with 10+ digits are treated as phone numbers. Runs longer than one number (e.g. two
    // numbers separated by a space) are masked as a whole, so nothing leaks: over-masking is the safe side.
    private static final Pattern NUMBER_IN_TEXT = Pattern.compile('(?<![0-9])\\+?[0-9][0-9 \\-]{8,30}[0-9](?![0-9])');
    private static final Integer MIN_TEXT_DIGITS = 10;
    private static final Integer NATIONAL_NUMBER_LENGTH = 10;

    /**
     * @description Reduces a number to digits and removes the international prefix (00), the
     *              configured country code (91) in front of a 10-digit number, or a leading trunk 0.
     *              '+91 98765-43221' => '9876543221'.
     */
    public static String normalize(String rawNumber) {
        if (String.isBlank(rawNumber)) {
            return '';
        }
        String digits = rawNumber.replaceAll('[^0-9]', '');
        if (digits.startsWith('00')) {
            digits = digits.substring(2);
        }
        String countryCode = PhoneMaskingConfig.countryCode();
        if (String.isNotBlank(countryCode)
                && digits.length() == countryCode.length() + NATIONAL_NUMBER_LENGTH
                && digits.startsWith(countryCode)) {
            digits = digits.substring(countryCode.length());
        } else if (digits.length() == NATIONAL_NUMBER_LENGTH + 1 && digits.startsWith('0')) {
            digits = digits.substring(1);
        }
        return digits;
    }

    /**
     * @description Masks one number. null stays null; blank or digit-free input returns ''.
     *              Numbers too short to keep both ends visible are masked completely.
     */
    public static String mask(String rawNumber) {
        if (rawNumber == null) {
            return null;
        }
        String digits = normalize(rawNumber);
        if (digits.length() == 0) {
            return '';
        }
        Integer prefix = PhoneMaskingConfig.prefixDigits();
        Integer suffix = PhoneMaskingConfig.suffixDigits();
        String maskChar = PhoneMaskingConfig.maskCharacter();

        if (digits.length() <= prefix + suffix) {
            return maskChar.repeat(digits.length());
        }
        return digits.left(prefix) + maskChar.repeat(digits.length() - prefix - suffix) + digits.right(suffix);
    }

    /**
     * @description Masks a list of numbers, keeping the order. A null list returns an empty list.
     */
    public static List<String> maskAll(List<String> rawNumbers) {
        List<String> masked = new List<String>();
        if (rawNumbers == null) {
            return masked;
        }
        for (String rawNumber : rawNumbers) {
            masked.add(mask(rawNumber));
        }
        return masked;
    }

    /**
     * @description True if the text contains something that looks like a phone number (10+ digits).
     */
    public static Boolean containsPhoneNumber(String text) {
        if (String.isBlank(text)) {
            return false;
        }
        Matcher matcher = NUMBER_IN_TEXT.matcher(text);
        while (matcher.find()) {
            if (isPhoneLength(matcher.group())) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Masks every phone number found inside free text, leaving the rest unchanged.
     *              'Call 9876543221 today' => 'Call 98XXXXXX21 today'.
     */
    public static String maskInText(String text) {
        if (String.isBlank(text)) {
            return text;
        }
        Matcher matcher = NUMBER_IN_TEXT.matcher(text);
        List<String> parts = new List<String>();
        Integer lastEnd = 0;
        while (matcher.find()) {
            String candidate = matcher.group();
            if (!isPhoneLength(candidate)) {
                continue;
            }
            parts.add(text.substring(lastEnd, matcher.start()));
            parts.add(mask(candidate));
            lastEnd = matcher.end();
        }
        if (parts.isEmpty()) {
            return text;
        }
        parts.add(text.substring(lastEnd));
        return String.join(parts, '');
    }

    private static Boolean isPhoneLength(String candidate) {
        return candidate.replaceAll('[^0-9]', '').length() >= MIN_TEXT_DIGITS;
    }
}
