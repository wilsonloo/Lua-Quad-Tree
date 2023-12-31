# lua 语言版本的 四叉树
* 只需要 quad_tree.lua
* 矩形采用左下角(x,y) 为起点，(w,h) 为尺寸

## 如何使用
* 由 quad_tree.new 构建并返回一棵四叉树：
```lua
    -- 以左下角(x,y) 作为起点，宽度w，高度h创建 根四叉树
    ---@param node_limit number 一个区域最多容纳多少个节点，超出后，需要进行分解（默认为4）
    ---@param region_min_size number 一个区域的尺寸达到极限后，不再进行拆分（默认为1）
    function M.new(x, y, w, h, node_limit, region_min_size)
```

* 四叉树对象tree支持以下操作：
    * tree:add(id, x, y, w, h) 添加一个矩形，如果已经存在矩形，则进行修正
    * tree:del(id) 删除指定id的矩形
    * tree:get(id) 获取指定id的矩形
    * tree:update(id, x, y, w, h) 更新信息,如果w/h为nil，则要求必须当前有该节点的信息；如果不存在id的矩形，则进行add
    * tree:query(x, y, w, h)  查询与(x, y, w, h) 相交的id列表
    * tree:intersect(x1, y1, w1, h1, x2, y2, w2, h2)-- 返回两个区域的交集：左下角坐标，右上角坐标; 如果返回nil表示没有交集

## todo
* 通过扩展多个树，实现全坐标轴覆盖