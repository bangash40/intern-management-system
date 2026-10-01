import 'package:flutter/material.dart';

import '../utils/date_utils.dart';

/// A form field that opens a date picker. Shows the chosen date or a hint.
class DateField extends FormField<DateTime> {
  DateField({
    super.key,
    required String label,
    required DateTime firstDate,
    required DateTime lastDate,
    super.initialValue,
    ValueChanged<DateTime>? onChanged,
    super.validator,
  }) : super(
         builder: (state) {
           final context = state.context;
           return InkWell(
             borderRadius: BorderRadius.circular(12),
             onTap: () async {
               final picked = await showDatePicker(
                 context: context,
                 initialDate: state.value ?? DateTime.now(),
                 firstDate: firstDate,
                 lastDate: lastDate,
               );
               if (picked != null) {
                 state.didChange(picked);
                 onChanged?.call(picked);
               }
             },
             child: InputDecorator(
               decoration: InputDecoration(
                 labelText: label,
                 prefixIcon: const Icon(Icons.event_outlined),
                 errorText: state.errorText,
               ),
               child: Text(
                 state.value == null
                     ? 'Select a date'
                     : AppDateUtils.formatDate(state.value!),
               ),
             ),
           );
         },
       );
}
