---@meta

---TreeSitter Node
---@class TSNode
---@field type fun(self: TSNode): string ノードのタイプを取得
---@field parent fun(self: TSNode): TSNode|nil 親ノードを取得
---@field range fun(self: TSNode): number, number, number, number ノードの範囲を取得(start_row, start_col, end_row, end_col)
---@field named_descendant_for_range fun(self: TSNode, start_row: number, start_col: number, end_row: number, end_col: number): TSNode|nil 指定範囲内の名前付き子孫ノードを取得
