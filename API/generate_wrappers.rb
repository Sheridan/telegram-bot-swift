#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require 'fileutils'

HTML_FILE = 'api.html'
API_DIR = '../Sources/TelegramBot'
API_FILE = 'api.txt'

TYPE_HEADER = <<EOT
// Telegram Bot SDK for Swift (unofficial).
// This file is autogenerated by API/generate_wrappers.rb script.

import Foundation
import SwiftyJSON

EOT

METHOD_HEADER = <<EOT
// Telegram Bot SDK for Swift (unofficial).
// This file is autogenerated by API/generate_wrappers.rb script.

import Foundation
import Dispatch

EOT

# Some of the variables have more convenient manually created helper methods,
# rename the original strings to something else
def make_getter_name(type_name, var_name, var_type, var_desc)
  case [type_name, var_name]
  #when ['Chat', 'type']
  #    return 'type_string'
  when ['ChatMember', 'status']
      return 'status_string'
  else
      if var_name == 'type' && var_type == 'String' then
          return 'type_string'
      elsif var_name.include?('date') && var_desc.include?('Unix time') then
          return var_name + '_unix'
      end
      return var_name
  end
end

def write_getter_setter(out, getter_name, type_name, var_name, var_type, var_optional, var_desc)
  init_params = {}

  var_desc.each_line { |line|
    out.write "    /// #{line.strip}\n"\
  }

  # Telegram docs describe some booleans as 'True' type instead of 'Boolean' type.
  # Optional 'True' works exactly as 'Boolean'.
  # Non-optional 'True' works as 'Boolean', but defaults to true on structure initialization.

  case [var_type, var_optional]
  when ['String', true]
    out.write "    public var #{getter_name}: String? {\n"\
              "        get { return json[\"#{var_name}\"].string }\n"\
              "        set { json[\"#{var_name}\"].string = newValue }\n"\
              "    }\n"
  when ['String', false]
    out.write "    public var #{getter_name}: String {\n"\
              "        get { return json[\"#{var_name}\"].stringValue }\n"\
              "        set { json[\"#{var_name}\"].stringValue = newValue }\n"\
              "    }\n"
  when ['Integer', true]
    is64bit = var_name.include?("user_id") || var_name.include?("chat_id") || var_desc.include?("64 bit integer") ||
              (type_name == 'User' && var_name == 'id')
    suffix = is64bit ? '64' : ''
    out.write "    public var #{getter_name}: Int#{suffix}? {\n"\
              "        get { return json[\"#{var_name}\"].int#{suffix} }\n"\
              "        set { json[\"#{var_name}\"].int#{suffix} = newValue }\n"\
              "    }\n"
  when ['Integer', false]
    is64bit = var_name.include?("user_id") || var_name.include?("chat_id") || var_desc.include?("64 bit integer") ||
              (type_name == 'User' && var_name == 'id')
    suffix = is64bit ? '64' : ''
    out.write "    public var #{getter_name}: Int#{suffix} {\n"\
              "        get { return json[\"#{var_name}\"].int#{suffix}Value }\n"\
              "        set { json[\"#{var_name}\"].int#{suffix}Value = newValue }\n"\
              "    }\n"
  when ['Float number', true], ['Float', true]
    out.write "    public var #{getter_name}: Float? {\n"\
              "        get { return json[\"#{var_name}\"].float }\n"\
              "        set { json[\"#{var_name}\"].float = newValue }\n"\
              "    }\n"
  when ['Float number', false], ['Float', false]
    out.write "    public var #{getter_name}: Float {\n"\
              "        get { return json[\"#{var_name}\"].floatValue }\n"\
              "        set { json[\"#{var_name}\"].floatValue = newValue }\n"\
              "    }\n"
  when ['Boolean', true], ['True', true]
    out.write "    public var #{getter_name}: Bool? {\n"\
              "        get { return json[\"#{var_name}\"].bool }\n"\
              "        set { json[\"#{var_name}\"].bool = newValue }\n"\
              "    }\n"
  when ['Boolean', false], ['True', false]
    if var_type == 'True' then
      init_params = { "#{var_name}" => "true" }
    end
    out.write "    public var #{getter_name}: Bool {\n"\
              "        get { return json[\"#{var_name}\"].boolValue }\n"\
              "        set { json[\"#{var_name}\"].boolValue = newValue }\n"\
              "    }\n"
  else
    two_d_array_prefix = 'Array of Array of '
    array_prefix = 'Array of '
    if var_type.start_with?(two_d_array_prefix) then
      var_type.slice! two_d_array_prefix
      # Present optional arrays as empty arrays
      if var_optional then
        out.write "    public var #{getter_name}: [[#{var_type}]] {\n"\
                  "        get { return json[\"#{var_name}\"].twoDArrayValue() }\n"\
                  "        set {\n"\
                  "            if newValue.isEmpty {\n"\
                  "                json[\"#{var_name}\"] = JSON.null\n"\
                  "                return\n"\
                  "            }\n"\
                  "            var rowsJson = [JSON]()\n"\
                  "            rowsJson.reserveCapacity(newValue.count)\n"\
                  "            for row in newValue {\n"\
                  "                var colsJson = [JSON]()\n"\
                  "                colsJson.reserveCapacity(row.count)\n"\
                  "                for col in row {\n"\
                  "                    let json = col.json\n"\
                  "                    colsJson.append(json)\n"\
                  "                }\n"\
                  "                rowsJson.append(JSON(colsJson))\n"\
                  "            }\n"\
                  "            json[\"#{var_name}\"] = JSON(rowsJson)\n"\
                  "        }\n"\
                  "    }\n"
      else
        out.write "    public var #{getter_name}: [[#{var_type}]] {\n"\
                  "        get { return json[\"#{var_name}\"].twoDArrayValue() }\n"\
                  "        set {\n"\
                  "            var rowsJson = [JSON]()\n"\
                  "            rowsJson.reserveCapacity(newValue.count)\n"\
                  "            for row in newValue {\n"\
                  "                var colsJson = [JSON]()\n"\
                  "                colsJson.reserveCapacity(row.count)\n"\
                  "                for col in row {\n"\
                  "                    let json = col.json\n"\
                  "                    colsJson.append(json)\n"\
                  "                }\n"\
                  "                rowsJson.append(JSON(colsJson))\n"\
                  "            }\n"\
                  "            json[\"#{var_name}\"] = JSON(rowsJson)\n"\
                  "        }\n"\
                  "    }\n"
      end
    elsif var_type.start_with?(array_prefix) then
      var_type.slice! array_prefix
      # Present optional arrays as empty arrays
      if var_optional then
        out.write "    public var #{getter_name}: [#{var_type}] {\n"\
                  "        get { return json[\"#{var_name}\"].arrayValue() }\n"\
                  "        set { json[\"#{var_name}\"] = newValue.isEmpty ? JSON.null : JSON.initFrom(newValue) }\n"\
                  "    }\n"
      else
        out.write "    public var #{getter_name}: [#{var_type}] {\n"\
                  "        get { return json[\"#{var_name}\"].arrayValue() }\n"\
                  "        set { json[\"#{var_name}\"] = JSON.initFrom(newValue) }\n"\
                  "    }\n"
      end
    else
      if var_optional then
        out.write "    public var #{getter_name}: #{var_type}? {\n"\
                  "        get {\n"\
                  "            let value = json[\"#{var_name}\"]\n"\
                  "            return value.isNullOrUnknown ? nil : #{var_type}(json: value)\n"\
                  "        }\n"\
                  "        set {\n"\
                  "            json[\"#{var_name}\"] = newValue?.json ?? JSON.null\n"\
                  "        }\n"\
                  "    }\n"
      else
        out.write "    public var #{getter_name}: #{var_type} {\n"\
                  "        get { return #{var_type}(json: json[\"#{var_name}\"]) }\n"\
                  "        set { json[\"#{var_name}\"] = newValue.json }\n"\
                  "    }\n"
      end
      #out.write "    //public var #{var_name}: #{var_type}#{var_optional ? '?' : ''} // TODO: Unsupported type\n"
    end
  end
  return init_params
end

def make_swift_type_name(var_name, var_type)
  array_prefix = 'Array of '
  if var_type.start_with?(array_prefix) then
    var_type.slice! array_prefix
    return "[#{var_type}]"
  end

  case var_type
  when 'Boolean', 'True'
    return 'Bool'
  when 'Integer'
    if var_name.include?('user_id') || var_name.include?('chat_id') then
      return 'Int64'
    else
      return 'Int'
    end
  when 'Float number'
    return 'Float'
  when 'Integer or String'
    if var_name.include?('chat_id') then
      return 'ChatId'
    end
  when 'InputFile or String'
    return 'FileInfo'
  when 'InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply'
    return 'ReplyMarkup'
  when 'MessageOrBoolean'
    return 'MessageOrBool'
  end
  return var_type
end

def make_request_parameter(request_name, swift_type_name, var_name, var_type, var_optional, var_desc)
  return {"#{var_name}": "#{swift_type_name}#{var_optional ? '? = nil' : ''}"}
end

def make_request_value(request_name, swift_type_name, var_name, var_type, var_optional, var_desc)
  return {"#{var_name}": "#{var_name}"}
end

def deduce_result_type(description)
  type_name = description[/An (.+) objects is returned/, 1]
  return type_name unless type_name.nil?

  type_name = description[/returns an (.+) objects/, 1]
  return type_name unless type_name.nil?

  type_name = description[/in form of a (.+) object/, 1]
  return type_name unless type_name.nil?

  type_name = description[/, a (.+) object is returned/, 1]
  return type_name unless type_name.nil?

  type_name = description[/(\w+) is returned, otherwise True is returned/, 1]
  return "#{type_name}OrBoolean" unless type_name.nil?

  type_name = description[/(\w+) is returned/, 1]
  return type_name unless type_name.nil?

  type_name = description[/Returns a (.+) object/, 1]
  return type_name unless type_name.nil?

  type_name = description[/Returns (.+) on/, 1]
  return type_name unless type_name.nil?

  return 'Boolean'
end

def fetch_description(current_node)
  description = ''
  while !current_node.nil? && current_node.name != 'table' &&
      current_node.name != 'h4' do
    text = current_node.text.strip
    continue unless text.length != 0

    if description.length != 0 then
      description += "\n"
    end
    description += text
    current_node = current_node.next_element
  end
  return description, current_node
end

def generate_type(f, node)
  FileUtils.mkpath "#{API_DIR}/Types"

  current_node = node

  type_name = current_node.text
  File.open("#{API_DIR}/Types/#{type_name}.swift", "wb") { | out |
    out.write TYPE_HEADER
    
    current_node = current_node.next_element
    description, current_node = fetch_description(current_node)

    f.write "DESCRIPTION:\n#{description}\n"
    description.each_line { |line|
      out.write "/// #{line.strip}\n"
    }
    out.write "///\n"

    anchor = type_name.downcase
    out.write "/// - SeeAlso: <https://core.telegram.org/bots/api\##{anchor}>\n"\
              "\n"

    out.write "public struct #{type_name}: JsonConvertible {\n"\
              "    /// Original JSON for fields not yet added to Swift structures.\n"\
              "    public var json: JSON\n"

    all_init_params = {}

    current_node.search('tr').each { |node|
      td = node.search('td')
      next unless td[0].text != 'Field'

      var_name = td[0].text
      var_type = td[1].text
      var_desc = td[2].text
      var_optional = var_desc.start_with? "Optional"
      f.write "PARAM: #{var_name} [#{var_type}#{var_optional ? '?' : ''}]: #{var_desc}\n"

      getter_name = make_getter_name(type_name, var_name, var_type, var_desc)

      out.write "\n"
      init_params = write_getter_setter(out, getter_name, type_name, var_name, var_type, var_optional, var_desc)

      # Accumulate init params to pass them to constructor
      all_init_params.merge!(init_params)
    }

    if all_init_params.empty? then
      params = "[:]"
    else
      params = "[" + all_init_params.map { |k, v|
        "\"#{k}\": #{v}"
      }.join(', ') + "]"
    end

    out.write "\n"\
        "    public init(json: JSON = #{params}) {\n"\
        "        self.json = json\n"\
        "    }\n"

    out.write "}\n"
  }
end

def generate_method(f, node)
  FileUtils.mkpath "#{API_DIR}/Methods"

  current_node = node

  method_name = current_node.text
  File.open("#{API_DIR}/Methods/TelegramBot+#{method_name}.swift", "wb") { | out |
    out.write METHOD_HEADER

    out.write "public extension TelegramBot {\n"

    completion_name = method_name.slice(0,1).capitalize + method_name.slice(1..-1) + 'Completion'
    
    current_node = current_node.next_element
    description, current_node = fetch_description(current_node)

    result_type = deduce_result_type(description)
    result_type =  make_swift_type_name('', result_type)
    out.write "    typealias #{completion_name} = (_ result: #{result_type}?, _ error: DataTaskError?) -> ()\n"\
      "\n"

    f.write "DESCRIPTION:\n#{description}\n"

    anchor = method_name.downcase

    vars_desc = ''
    all_params = {}
    all_values = {}
    current_node.search('tr').each { |node|
      td = node.search('td')
      next unless td[0].text != 'Parameters'

      var_name = td[0].text
      var_type = td[1].text
      var_optional = td[2].text.strip != 'Yes'
      var_desc = td[3].text
      f.write "PARAM: #{var_name} [#{var_type}#{var_optional ? '?' : ''}]: #{var_desc}\n"

      swift_type_name = make_swift_type_name(var_name, var_type)
      param = make_request_parameter(method_name, swift_type_name, var_name, var_type, var_optional, var_desc)
      value = make_request_value(method_name, swift_type_name, var_name, var_type, var_optional, var_desc)

      # Accumulate init params to pass them to constructor
      all_params.merge!(param)
      all_values.merge!(value)

      if vars_desc.empty? then
        vars_desc += "    /// - Parameters:\n"
      end
      vars_desc +=   "    ///     - #{var_name}: "
      first_line = true
      var_desc.each_line { |line|
        stripped = line.strip
        next unless !stripped.empty?
        if first_line then
          first_line = false
        else
          vars_desc += '    ///       '
        end
        vars_desc +=   "#{line.strip}\n"\
      }
    }

    if all_params.empty? then
      params = ''
    else
      params = "\n            " + all_params.map { |k, v|
        "#{k}: #{v}"
      }.join(",\n            ")
    end

    if all_values.empty? then
      values = ''
    else
      values = "            " + all_values.map { |k, v|
        "\"#{k}\": #{v}"
      }.join(",\n            ")
    end

    # Generate Sync request
    description.each_line { |line| out.write "    /// #{line.strip}\n" }
    out.write vars_desc
    out.write "    /// - Returns: #{result_type} on success. Nil on error, in which case `TelegramBot.lastError` contains the details.\n"
    out.write "    /// - Note: Blocking version of the method.\n"
    out.write "    ///\n"
    out.write "    /// - SeeAlso: <https://core.telegram.org/bots/api\##{anchor}>\n"
    out.write "    @discardableResult\n"
    out.write "    public func #{method_name}Sync(#{params}#{!params.empty? ? ",\n            " : ''}"\
      "_ parameters: [String: Any?] = [:]) -> #{result_type}? {\n"
    out.write "        return requestSync(\"#{method_name}\", defaultParameters[\"#{method_name}\"], parameters"
    if !values.empty? then
        out.write ", [\n#{values}])\n"
    else
        out.write ")\n"
    end
    out.write "    }\n"

    out.write "\n"

    # Generate Async request
    description.each_line { |line| out.write "    /// #{line.strip}\n" }
    out.write vars_desc
    out.write "    /// - Returns: #{result_type} on success. Nil on error, in which case `error` contains the details.\n"
    out.write "    /// - Note: Asynchronous version of the method.\n"
    out.write "    ///\n"
    out.write "    /// - SeeAlso: <https://core.telegram.org/bots/api\##{anchor}>\n"
    out.write "    public func #{method_name}Async(#{params}#{!params.empty? ? ",\n            " : ''}"\
      "_ parameters: [String: Any?] = [:],\n"\
      "            queue: DispatchQueue = .main,\n"\
      "            completion: #{completion_name}? = nil) {\n"
    out.write "        return requestAsync(\"#{method_name}\", defaultParameters[\"#{method_name}\"], parameters"
    if !values.empty? then
        out.write ", [\n#{values}]"
    end
    out.write ",\n"\
      "            queue: queue, completion: completion)\n"
    out.write "    }\n"
    out.write "}\n\n"
  }

end

def main
  STDOUT.sync = true

  File.open(API_FILE, 'wb') { |f|
    html = File.open(HTML_FILE, "rb").read
    doc = Nokogiri::HTML(html)

    doc.css("br").each { |node| node.replace("\n") }
    
    doc.search("h4").each { |node|
      title = node.text.strip
      next unless title.split.count == 1

      # These types are complex and created manually:
      next unless !['InlineQueryResult', 'InputFile'].include?(title)

      kind = (title.chars.first == title.chars.first.upcase) ? :type : :method

      f.write "NAME: #{title} [#{kind}]\n"

      if kind == :type then
        generate_type f, node
      else
        generate_method f, node
      end

      f.write "\n"
    }
  }


  puts 'Finished'
end

if $0 == __FILE__
  if File.new(__FILE__).flock(File::LOCK_EX | File::LOCK_NB)
    main
  else
    raise 'Another instance of this program is running'
  end
end
