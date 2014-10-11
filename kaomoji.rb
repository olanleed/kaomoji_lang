#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class Env < Hash
  def initialize(parms = [], args = [], outer = nil)
    h = Hash[parms.zip(args)]
    self.merge!(h)
    self.merge!(yield) if block_given?
    @outer = outer
  end

  def find(key)
    self.has_key?(key) ? self : @outer.find(key)
  end
end

$global_env = Env.new do {
    :+       => -> x, y{ x + y },
    :-       => -> x, y{ x - y },
    :*       => -> x, y{ x * y },
    :/       => -> x, y{ x / y },
    :not     => -> x{ !x },
    :>       => -> x, y{ x > y },
    :<       => -> x, y{ x < y },
    :>=      => -> x, y{ x >= y },
    :<=      => -> x, y{ x <= y },
    :'='     => -> x, y{ x == y },
    :modulo  => -> x, y{ x % y },
    :equal?  => -> x, y{ x.equal?(y) },
    :eq?     => -> x, y{ x.eql? y},
    :length  => -> x{ x.length },
    :cons    => -> x, y{ [x, y] },
    :car     => -> x{ x[0] },
    :cdr     => -> x{ x[1..-1] },
    :append  => -> x, y{ x + y },
    :list    => -> *x{ [*x] },
    :list?   => -> *x{ x.instance_of?(Array) },
    :null?   => -> x{ x.empty? },
    :symbol? => -> x{ x.instance_of?(Symbol) }
  }
end

def evaluate(x, env = $global_env)
  tmp = x
  case x
  when Symbol
    env.find(x)[x]
  when Array
    case x.first
    when :quote
      _, exp = x
      exp
    when :if
      _, test, conseq, alt = x
      evaluate((evaluate(test, env) ? conseq : alt), env)
    when :set!
      _, var, exp = x
      env.find(var)[var] = evaluate(exp, env)
    when :define
      _, var, exp = x
      env[var] = evaluate(exp, env)
      nil
    when :lambda
      _, vars, exp = x
      lambda { |*args| evaluate(exp, Env.new(vars, args, env)) }
    when :begin
      x[1..-1].inject(nil) { |val, exp| val = evaluate(exp, env) }
    when :display
      _, exp = x
      to_string(evaluate(exp)) unless exp.nil?
    else
      proc, *exps = x.inject([]) { |mem, exp| mem << evaluate(exp, env) }
      proc[*exps]
    end
  else
    x
  end
end

def tokenize(s)
  s.gsub(/[(")]/, ' \0 ').split
end

def read(s)
  read_from tokenize(s)
end
alias :parse :read

def read_from(tokens)
  raise SytaxError, 'unexpected EOF while reading' if tokens.length == 0
  case token = tokens.shift
  when '('
    l = []
    until tokens[0] == ')'
      l.push read_from(tokens)
    end
    tokens.shift
    l
  when ')'
    raise SyntaxError, 'unexpected )'
  else
    atom(token)
  end
end

module Kernel
  def Symbol(obj);
    obj.intern
  end
end

def atom(token, type = [:Integer, :Float, :Symbol])
  send(type.shift, token)
rescue ArgumentError
  retry
rescue => e
  puts "unexpected error: #{e.message}"
end

def to_string(exp)
  print (exp.instance_of?(Array)) ? '(' + exp.map(&:to_s).join(" ") + ')' : "#{exp}"
end

def replace(s)
  s = s.gsub('( ˘⊖˘) 。o', '')
    .gsub('(^o^)', '+')
    .gsub('▂▅▇█▓▒░(’ω’)░▒▓█▇▅▂', '-')
    .gsub('( ✹‿✹ )開眼だァーーーーーーーーーーー！！！！！！！！！！！', '*')
    .gsub('((☛(◜◔。◔◝)☚))', '/')
    .gsub('L(՞ਊ՞)｣', '=')
    .gsub('( ◠‿◠ )☛', 'lambda')
    .gsub('(´へωへ`*)', 'define')
    .gsub('(´へεへ`*) ＜', 'display')
    #.gsub('', '')
end

def lepl
  IO.foreach(ARGV[0], :encoding => Encoding::UTF_8) do |line|
    puts "line(1) : #{line}"
    line = replace line
    val = evaluate(parse line)
  end
end

lepl if __FILE__ == $0
