import 'package:formz/formz.dart';

enum PhoneNumberValidationError { empty, invalidFormat }

class PhoneNumber extends FormzInput<String, PhoneNumberValidationError> {
  const PhoneNumber.pure() : super.pure('');
  const PhoneNumber.dirty([super.value = '']) : super.dirty();

  static final RegExp _phoneRegExp = RegExp(
    r'^0[0-9]{9}$', 
  );

  @override
  PhoneNumberValidationError? validator(String value) {
    if (value.isEmpty) return PhoneNumberValidationError.empty;
    return _phoneRegExp.hasMatch(value) 
        ? null 
        : PhoneNumberValidationError.invalidFormat;
  }
}