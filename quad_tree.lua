local tinsert = table.insert
local tremove = table.remove

local mmin = math.min
local mmax = math.max

local REGION_SLOT_RT = 1 -- 右上角
local REGION_SLOT_RD = 2 -- 右下角
local REGION_SLOT_LD = 3 -- 左下角
local REGION_SLOT_LT = 4 -- 左上角

local function create_region(x, y, w, h)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        
        nodes = nil,
        children = nil,
    }
end

local function split_region(self, region)
    local w = region.w/2
    local h = region.h/2
    local children = {}
    children[REGION_SLOT_LD] = create_region(region.x, region.y, w, h) -- 左下角
    children[REGION_SLOT_LT] = create_region(region.x, region.y+region.h/2, w, h) -- 左上角
    children[REGION_SLOT_RT] = create_region(region.x+w, region.y+h, w, h) -- 右上角
    children[REGION_SLOT_RD] = create_region(region.x+w, region.y, w, h) -- 右下角
    region.children = children
end

local function create_node(id, x, y, w, h)
    return {
        id = id,
        x = x,
        y = y,
        w = w,
        h = h,
    }
end

local function add_to_children(self, id, x, y, w, children)
    for _, child in ipairs(region.children) do
        local ld_x, ld_y, rt_x, rt_y = self:intersect(node.x, node.y, node.w, node.h, child.x, child.y, child.w, child.h)
        if ld_x then
            add_node(self, v.id, ld_x, ld_y, rt_x-ld_x, rt_y-ld_y, child)
        end
    end
end

local function add_node(self, id, x, y, w, h, region)
    if region.nodes then
        if #region.nodes >= self.node_limit then
            if region.w > self.region_min_size and region.h > self.region_min_size then
                local nodes = region.nodes
                region.nodes = nil
                split_region(self, region)
                for _, v in ipairs(nodes) do
                    add_to_children(self, v.id, v.x, v.y, v.w, v.h, region.children)
                end
            end
        end
    end

    if region.children then
        add_to_children(self, id, x, y, w, h, region.children)
        return
    end

    if not region.nodes then
        region.nodes = {}
    end

    local new_node = create_node(id, x, y, w, h)
    tinsert(region.nodes, new_node)
end

local function del_node(self, region, id, x, y, w, h)
    if region.nodes then
        for k, v in ipairs(region.nodes) do
            if v.id == id then
                tremove(region.nodes, k)
                return
            end
        end
    end

    if region.children then
        for _, child in ipairs(region.children) do
            local ld_x, ld_y, rt_x, rt_y = self:intersect(x, y, w, h, child.x, child.y, child.w, child.h)
            if ld_x then
                del_node(self, child, ld_x, ld_y, rt_x-ld_x, rt_y - ld_y)
            end
        end
    end
end

local function query_intersect(self, x, y, w, h, region, set)
    if not self:intersect(x, y, w, h, region.x, region.y, region.w, region.h) then
        return
    end

    if region.nodes then
        for _, node in ipairs(region.nodes) do
            if self:intersect(x, y, w, h, node.x, node.y, node.w, node.h) then
                set[node.id] = true
            end
        end
        assert(not region.children)
        return
    end

    if region.children then
        for _, child in ipairs(region.children) do
            query_intersect(self, x, y, w, h, child, set)
        end
    end
end

local mt = {}
mt.__index = mt

function mt:get(id)
    return self.node_map[id]
end

function mt:add(id, x, y, w, h)
    local node = self:get(id)
    if node then
        del_node(self, self, node.id, node.x, node.y, node.w, node.h)
    end

    add_node(self, id, x, y, w, h, self)
    self.node_map[id] = create_node(id, x, y, w, h)
end

function mt:del(id)
    local node = self:get(id)
    if node then
        del_node(self, self, node.id, node.x, node.y, node.w, node.h)
        self.node_map[id] = nil
    end
end

-- 更新信息,如果w/h为nil，则要求必须当前有该节点的信息
function mt:update(id, x, y, w, h)
    local node = self:get(id)
    if node then
        del_node(self, self, node.id, node.x, node.y, node.w, node.h)
        if not h then
            w = w or node.w
            h = h or node.h
        end
    else
        assert(w, "missing w")
        assert(h, "missing h")
    end

    add_node(self, id, x, y, w, h, self)
end

-- 查询与(x, y, w, h) 相交的id列表
function mt:query(x, y, w, h)
    local set = {}
    query_intersect(self, x, y, w, h, self, set)

    if next(set) then
        local out = {}
        for id in pairs(set) do
            tinsert(out, id)
        end
        return out
    end
end

-- 返回两个区域的交集：左下角坐标，右上角坐标
-- 如果返回nil表示没有交集
function mt:intersect(x1, y1, w1, h1, x2, y2, w2, h2)
    local ld_x = mmax(x1, x2)
    local ld_y = mmax(y1, y2)

    local rt_x = mmin(x1+w1, x2+w2)
    local rt_y = mmin(y1+h1, y2+h2)

    if rt_x - ld_x > 0 and rt_y - ld_y > 0 then
        return ld_x, ld_y, rt_x, rt_y
    end
end


local M = {}

-- 以左下角(x,y) 作为起点，宽度w，高度h创建 根四叉树
---@param node_limit number 一个区域最多容纳多少个节点，超出后，需要进行分解（默认为4）
---@param region_min_size number 一个区域的尺寸达到极限后，不再进行拆分（默认为1）
function M.new(x, y, w, h, node_limit, region_min_size)
    local tree = create_region(x, y, w, h)
    tree.node_limit = node_limit or 4
    tree.region_min_size = region_min_size or 1
    tree.node_map = {}

    setmetatable(tree, mt)
    return tree
end

return M