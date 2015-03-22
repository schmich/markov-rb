#!env ruby

class LetterTokenizer
  def tokenize(text)
    text.each_char do |c|
      yield c
    end
  end
end

class LetterSymbolizer
  def symbolize(text)
    text.downcase
  end
end

class MarkovChain
  def initialize(tokenizer, symbolizer, degree)
    @tokenizer = tokenizer
    @symbolizer = symbolizer
    @random = Random.new
    @degree = degree

    @table = {}
  end

  def add_document(text)
    prev_states = [nil] * @degree

    @tokenizer.tokenize(text) do |token|
      symbol = @symbolizer.symbolize(token)

      link(prev_states, symbol)

      prev_states = prev_states.dup
      prev_states.shift
      prev_states.push(symbol)
    end

    link(prev_states, nil)
  end

  def link(prev_states, symbol)
    @table[prev_states] ||= {}
    @table[prev_states][symbol] ||= 0
    @table[prev_states][symbol] += 1
  end

  def generate()
    text = ''
    prev_states = [nil] * @degree

    loop do
      symbol = next_symbol(@table[prev_states])
      if !symbol
        break
      end

      text += symbol[0]

      prev_states = prev_states.dup
      prev_states.shift
      prev_states.push(symbol)
    end

    return text
  end

  def next_symbol(prev_states)
    total = prev_states.inject(0) { |acc, next_symbol| acc + next_symbol[1] }
    select = @random.rand(total) + 1

    cur = 1
    prev_states.each do |symbol, count|
      cur += count

      if select < cur
        return symbol
      end
    end
  end
end

def name_case(text)
  text.split(/([^[[:word:]]])/).map(&:capitalize).join
end

def print_names(source, degree, count)
  chain = MarkovChain.new(LetterTokenizer.new, LetterSymbolizer.new, degree)

  names = File.read(ARGV[0]).lines.map(&:strip)
  names.each do |name|
    chain.add_document(name)
  end

  count.times do
    puts name_case(chain.generate)
  end
end

print_names(ARGV[0], (ARGV[1] || 2).to_i, 15)
