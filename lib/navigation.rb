%w(error navigator).each do |f|
  require File.join(File.dirname(__FILE__), 'navigation', f)
end
# = NavigationHelper
# Use this plugin if you are seeking a navigation solution that keeps track of 
# the current tab or section, and returns an unordered list of links for easy
# styling in CSS.
# 
# == Get it at GitHub
# This repository is public on GitHub:
#
#  git clone git://github.com/rpheath/navigation_helper.git
#
# == Examples
# see the README for more details and a full list of example usage
module RPH
  module Navigation
    SUBTITLES, ROUTES, ICONS = {}, {}, {}
    
    # InstanceMethods will be mixed in with ActionView::Base which will
    # make the navigation helper available to any view
    module InstanceMethods
      # called from any view and will return an unordered list containing
      # links to the sections passed in
      #
      # Example:
      #   <%= navigation [:home, :about, :contact_me] -%>
      #
      # ...would render...
      #
      #   <ul class="nav_bar">
      #     <li class="current"><a href="/home">Home</a></li>
      #     <li><a href="/about">About</a></li>
      #     <li><a href="/contact">Contact Me</a></li>
      #   </ul>
      #
      # Configuration Options:
      # * +authorize+ - specifies which of the sections require authorization before showing up
      #   (note: use <tt>:authorize => [:all]</tt> if all sections require authorization... i.e, an admin menu)
      # * +with+ - specifies the method to use to authorize against (defaults to <tt>logged_in?</tt> method...
      #   Note - requires the <tt>authorize</tt> option to work)
      # * +hover_text+ - specifies to use the subtitles as hovertext instead of showing up as span's under the links
      def navigation(sections, options={})
        navigation, items = Navigator.new(sections, options), []

        navigation.sections.each do |link|
          css = 'current' if controller.class.current_tab.include?(link)
          
          #if navigation.methods_to_authorize.include?(link)
          #  result = content_tag(:li, construct(navigation, link), :class => [css.to_s, navigation.authorized_css.to_s].compact.join(' ')) if allowed?(navigation)
          #  items << result
          #else
            items << construct(
                        navigation,
                        link,
                        :wrap_in_div => options[:wrap_in_div],
                        :class => css.to_s)
          #end
        end
        
        return '' if items.blank?
        
        navigation_id ||= options[:navigation_id]
        navigation_css ||= options[:navigation_css]
        
        content_tag(:div, content_tag(:ul, items, :class => 'navigation'), :id => navigation_id, :class => navigation_css)
      end
      
      private
      # builds the actual link and determines if subtitles are present
      #def construct(nav, section)
      def construct(nav, section, opts={})
        # Some preprocessing
        text = ''
        text += "#{ICONS[section].to_s} " if nav.wants_icons?
        text += nav.text_for(section)
        
        path = ROUTES[section.to_sym] || send("#{section.to_s.downcase}_path")
        
        opts[:class] ||= false
        opts[:wrap_in_div] ||= false
        
        # constructing the links
        if opts[:wrap_in_div] # for sidebars, needing div dividers
          text = content_tag(:div, content_tag(:li, text), :class => opts[:class].to_s)
          result = link_to(text, path)

          result = link_to(text, path, :title => SUBTITLES[section]) if nav.wants_hover_text?
          result += content_tag(:span, SUBTITLES[section]) if nav.wants_subtitles?
          
          link = result
        else
          result = link_to(text, path)

          result = link_to(text, path, :title => SUBTITLES[section]) if nav.wants_hover_text?
          result += content_tag(:span, SUBTITLES[section]) if nav.wants_subtitles?
          link = content_tag(:li, result, :class => opts[:class].to_s)
        end
        link
      end

      # checks if the authorization method exists;
      # then checks the boolean value it returns
      def allowed?(navigation)
        controller.respond_to?(navigation.authorization_method) && controller.send(navigation.authorization_method)
      end 
    end

    # ClassMethods will be extended by ActionController::Base which will
    # make the current_tab method available to any controller inhereting 
    # from ActionController::Base
    module ClassMethods
      # used to set the current tab for any controller (defaults to current controller's name)
      # 
      # Example:
      #   class PublicController < ApplicationController
      #     current_tab :home
      #   end
      def current_tab(*tabs)
        self._current_tab = tabs unless tabs.empty?
        self._current_tab ||= self.to_s.sub('Controller', '').downcase.to_sym
      end      
    end
  end
end