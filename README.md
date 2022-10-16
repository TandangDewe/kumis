# Kumis Template Engine
Simple, Mustache-like, template engine implemented in Free Pascal.

## Using Kumis
Kumis only has 2 function and 2 callback.

Function :
```pascal
function Parse(const TplStr: string): TKumisElArr;
function Render(const Tpl: TKumisElArr; SectionCb: TSectionEvent; VariableCb: TVariableEvent;
  Data: Pointer = nil): string;
```

And callback :
```pascal
TSectionEvent = function(const AName: string; const Iterator: array of const;
  Data: Pointer): boolean;
TVariableEvent = function(const AName: string; const Iterator: array of const;
  Data: Pointer): string;
```

## Template Format
Template format is similar with mustache, but there are few different.

### Variable
```
{{variable_name}}
```
Replace content with value returned from `VariableCb`. Kumis don't make any interpretation about variable name. All character between "{{" and "}}" send to callback (in `AName` param) as is (even white space). No escape char applied.

### Sections
```
{{#section_name}}
...Content of section...
{{#section_name}}
```
Section is analogue of `while` in pascal. For every new section, new iterator will be created (TVarRec with zero-based integer value). If `SectionCb` return True, section will be processed repeatedly until it return False. Like `variable_name`, it's your responsibility to interpreted `section_name`.

### Sections Once
```
{{?section_name}}
...Content of section...
{{#section_name}}
```
Sections Once  analogue of `if` in pascal. If `SectionCb` return True, section will processed once. New iterator is *not* created inside 'content of section'. But inside `SectionCb` callback, new iterator created with 0 (zero) value.

### Inverted Sections
```
{{^section_name}}
...Content of section...
{{#section_name}}
```
Similar with Sections Once, but the logic is inverted.

### Set Delimiter
```
{{=new_start_delimiter new_end_delimiter=}}
```
Change delimiter. Make sure separated `new_start_delimiter` and `new_end_delimiter` with single space.

## Example
In kumistest.lpr you can find simple (but not very efficient) example for parse and render with Kumis using json data. 

## Additional Information
* It's in alpha state.
* I write Kumis with simplicity dan readability in mind. Put extra layer of protection if you get template and/or data from untrusted source.
