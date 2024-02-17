# vim-pets

Put small animals in your text editor.  
(As you know, this plugin is strongly inspired by [vscode-pets](https://marketplace.visualstudio.com/items?itemName=tonybaloney.vscode-pets))

**Pets**  
<img src=images/vi-pets.gif width="70%">

**PetsWithYou**  
<img src=images/vi-petswithyou.gif width="70%">

extension pack sample -> [vim-pets-ocean](https://github.com/MeF0504/vim-pets-ocean)

## Usage

### Put pets in the Vim window

Create garden with pets.
```
Pets [animal_name [nickname]]
```
After you create a garden of pets, you can add and remove pet as following.
```
PetsJoin animal_name [nickname]
PetsLeave [animal_name(nickname)]
```
You also can throw a ball
```
PetsThrowBall
```
To Close the garden, please do
```
PetsClose
```

### Put pets around the cursor

```vim
PetsWithYou animal_name
```
You can call this command repeatedly.
e.g.)
```vim
PetsWithYou dog
PetsWithYou dog
PetsWithYou cat
PetsWithYou rabbit
```

To clear pets,
```vim
PetsWithYouClear
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
- `g:pets_lifetime_enable` (number): Enable the 'lifetime' system. If set 1, pets will go about 10 minutes after join the garden. default: 1
- `g:pets_birth_enable` (number): Enable the 'birth' system. If set 1, new pet will born. default: 1
- `g:pets_garden_width` (number): Width of the garden. default: &columns/2
- `g:pets_garden_height` (number): Height of the garden. default: &lines/3
- `g:pets_garden_pos` (list): Setting of the position of the garden. This list contains three parameters, [line(number), collum(number), position(string)].
    - The Available argument of position is 'topleft', 'topright', 'botleft' and 'botright'.
    - In Vim, these values are assigned to the `line`, `col`, and `pos` parameters of popup_create-arguments.
    - In Neovim, these values are assigned to the `row`, `col`, and `anchor` parameters of nvim_open_win-config.
    The position argument is converted to fit the `nvim_open_win` function.
    - default: [&lines-&cmdheight-1, &columns-1, 'botright']

## Future Contents
* Plan to support showing image files
* [sample](images/vi-pets_image.gif)

NOTE: This is a very challenging function.
This is still limited and not stable.
### Requirements
* [libsixel](https://github.com/libsixel/libsixel) supported terminal emulator.
* img2sixel command


## License
[MIT](https://github.com/MeF0504/vim-pets/blob/main/LICENSE)

## Author
[MeF0504](https://github.com/MeF0504)
