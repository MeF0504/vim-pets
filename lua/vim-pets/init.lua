
local M = {}
M.ids = {}

function M.set_image(path, row, col, width, height)
    local id = vim.ui.img.set(vim.fn.readblob(path),
        {row=row, col=col, width=width, height=height, zindex=50}
    )
    M.ids[path] = id
    return id
end

function M.update_image(path, pre_id, row, col)
    -- new_id = M.ids[path]
    -- if new_id == nil then
    --     -- new image
    --     local opt = vim.ui.img.get(pre_id)
    --     local arg0 = path
    -- else
    --     -- image already exists
    --     local opt = {row=row, col=col}
    --     local arg0 = new_id
    -- end
    -- if new_id != pre_id then
    --     vim.ui.img.del(pre_id)
    -- end

    -- vim.ui.img.set(path, opt)
    -- print(pre_id, row, col)
    vim.ui.img.set(pre_id, {row=row, col=col})
    -- vim.ui.img.set(vim.fn.readblob(path),
    --     {row=row, col=col, width=2, height=1, zindex=50})
end

function M.close(id)
    vim.ui.img.del(id)
end

function M.clear()
    for key, val in pairs(M.ids) do
        vim.ui.img.del(val)
    end
    M.ids = {}
end

return M
