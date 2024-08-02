class Color < ApplicationRecord
  belongs_to :list

  # RGB値から16進数カラーコードを生成するメソッド
  def hex_color
    "#%02x%02x%02x" % [red, green, blue]
  end
end
