module Backstage
  class SidebarConfig
    SidebarLink = Struct.new(:label, :url_or_proc)

    attr_reader :links

    def initialize
      @links = []
    end

    def link(label, url_or_proc)
      @links << SidebarLink.new(label, url_or_proc)
    end
  end
end
