# vim-pets

Put small animals in your text editor.  
(As you know, this plugin is strongly inspired by [vscode-pets](https://marketplace.visualstudio.com/items?itemName=tonybaloney.vscode-pets))
<img src=images/vi-pets.gif width="70%">

## Usage

Create garden with pets.
```
Pets (animal name)
```
After you create a garden of pets, you can add and remove pet as following.
```
PetsAdd (animal name)
PetsLeave [animal name]
```
To Close the garden, please do
```
PetsClose
```

## Requirements

- `rand()`
```vim
echo exists('*rand') "=1
```
- `popupwin` or `nvim`
```vim
echo has('popupwin') "=1
" or
echo has('nvim') "=1
```

## Installation

For [vim-plug](https://github.com/junegunn/vim-plug) plugin manager:

```vim
Plug 'MeF0504/vim-pets'
```

## License
[MIT](https://github.com/MeF0504/vim-pets/blob/main/LICENSE)

## Author
[MeF0504](https://github.com/MeF0504)
