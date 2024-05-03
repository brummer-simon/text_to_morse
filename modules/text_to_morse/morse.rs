// SPDX-License-Identifier: Dual MPL/GPL
// Author: Simon Brummer <simon.brummer@posteo.de>

/// Convert a character into its morse code representation
///
/// # Arguments
/// * char: The character (UTF-8) to convert into morse code.
///
/// # Returns
/// A reference to str containing the morse code representation of argument char.
///
/// # Note
/// The values in the lookup table come from https://en.wikipedia.org/wiki/Morse_code.
/// All whitespaces/control characters are just mapped to the their values
/// and unknown characters are mapped to ........ (the official error sequence)
pub(crate) fn morse_code_from(char: char) -> &'static str {
    match char {
        // Latin letters
        'A' | 'a' => ".-",
        'B' | 'b' => "-...",
        'C' | 'c' => "-.-.",
        'D' | 'd' => "-..",
        'E' | 'e' => ".",
        'F' | 'f' => "..-.",
        'G' | 'g' => "--.",
        'H' | 'h' => "....",
        'I' | 'i' => "..",
        'J' | 'j' => ".---",
        'K' | 'k' => "-.-",
        'L' | 'l' => ".-..",
        'M' | 'm' => "--",
        'N' | 'n' => "-.",
        'O' | 'o' => "---",
        'P' | 'p' => ".--.",
        'Q' | 'q' => "--.-",
        'R' | 'r' => ".-.",
        'S' | 's' => "...",
        'T' | 't' => "-",
        'U' | 'u' => "..-",
        'V' | 'v' => "...-",
        'W' | 'w' => ".--",
        'X' | 'x' => "-..-",
        'Y' | 'y' => "-.--",
        'Z' | 'z' => "--..",
        // Numbers
        '0' => "-----",
        '1' => ".----",
        '2' => "..---",
        '3' => "...--",
        '4' => "....-",
        '5' => ".....",
        '6' => "-....",
        '7' => "--...",
        '8' => "---..",
        '9' => "----.",
        // Special characters
        'À' | 'à' | 'Å' | 'å' => ".--.-",
        'Ä' | 'ä' => ".-.-",
        'È' | 'è' => ".-..-",
        'É' | 'é' => "..-..",
        'Ö' | 'ö' => "---.",
        'Ü' | 'ü' => "..--",
        'ß' => "...--..",
        'Ñ' | 'ñ' => "--.--",
        // Punctuation characters
        '.' => ".-.-.-",
        ',' => "--..--",
        ':' => "---...",
        ';' => "-.-.-.",
        '?' => "..--..",
        '!' => "-.-.--",
        '-' => "-....-",
        '_' => "..--.-",
        '(' => "-.--.",
        ')' => "-.--.-",
        '\'' => ".----.",
        '=' => "-...-",
        '+' => ".-.-.",
        '/' => "-..-.",
        '@' => ".--.-.",
        '"' => ".--.-.",
        // Whitespace / control characters
        ' ' => " ",
        '\n' => "\n",
        '\r' => "\r",
        '\t' => "\t",
        '\0' => "\0",
        // Everything else is mapped to Error
        _ => "........",
    }
}
