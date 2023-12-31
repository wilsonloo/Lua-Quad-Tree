local QuadTree = require "quad_tree"
local PrintR = require "testcase.print_r"

local tree = QuadTree.new(-500, -500, 1000, 1000, 4, 1)
local ret
local x, y, w, h

local id = "id-101"
tree:add(id, -50, -50, 100, 100)
ret = tree:get(id)
PrintR.print_r(id, ret)
assert(ret)

ret = tree:query(100, 100, 10, 10)
PrintR.print_r("query ret:", ret)
assert(not ret)

print("====================")
x, y, w, h = 0, 0, 50, 50
ret = tree:query(x, y, w, h)
PrintR.print_r("query ret:", ret)
assert(ret)
for _, id in ipairs(ret) do
    local node = tree:get(id)
    assert(node, id)
    local ld_x, ld_y, rt_x, rt_y = tree:intersect(x, y, w, h, node.x, node.y, node.w, node.h)
    print("intersect with:", id, ld_x, ld_y, rt_x, rt_y)
    assert(ld_x == x)
    assert(ld_y == y)
    assert(rt_x-ld_x == w)
    assert(rt_y-ld_y == h)
end

id = "id-102"
tree:add(id, 0, -100, 100, 100)
ret = tree:get(id)
PrintR.print_r(id, ret)
assert(ret)

print("====================")
x, y, w, h = 10, -10, 10, 10
ret = tree:query(x, y, w, h)
PrintR.print_r("query ret:", ret)
assert(ret and #ret == 2)
for _, id in ipairs(ret) do
    local node = tree:get(id)
    assert(node, id)
    local ld_x, ld_y, rt_x, rt_y = tree:intersect(x, y, w, h, node.x, node.y, node.w, node.h)
    print("intersect with:", id, ld_x, ld_y, rt_x, rt_y)
    assert(ld_x == x)
    assert(ld_y == y)
    assert(rt_x-ld_x == w)
    assert(rt_y-ld_y == h)
end

print("all successed")