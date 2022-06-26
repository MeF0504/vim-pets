# vim-pets

Put small animals in your text editor.  
(As you know, this plugin is strongly inspired by [vscode-pets](https://marketplace.visualstudio.com/items?itemName=tonybaloney.vscode-pets))
<img src=images/vi-pets.gif width="70%">

extension pack sample -> [vim-pets-ocean](https://github.com/MeF0504/vim-pets-ocean)

## Usage

Create garden with pets.
```
Pets [animal name]
```
After you create a garden of pets, you can add and remove pet as following.
```
PetsJoin (animal name)
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

## Options

- `g:pets_default_pet` (string): The pet name joinning when `:Pets` command called without specify the pet name. default: 'dog'
- `g:pets_garden_width` (number): Width of the garden. default: &columns/2
- `g:pets_garden_height` (number): Height of the garden. default: &lines/3
- `g:pets_garden_pos` (list): Setting of the position of the garden. This list contains three parameters, [line(number), collum(number), position(string)].
    - The Available argument of position is 'topleft', 'topright', 'botleft' and 'botright'.
    - In Vim, these values are assigned to the `line`, `col`, and `pos` parameters of popup_create-arguments.
    - In Neovim, these values are assigned to the `row`, `col`, and `anchor` parameters of nvim_open_win-config.
    The position argument is converted to fit the `nvim_open_win` function.

## License
[MIT](https://github.com/MeF0504/vim-pets/blob/main/LICENSE)

## Author
[MeF0504](https://github.com/MeF0504)
