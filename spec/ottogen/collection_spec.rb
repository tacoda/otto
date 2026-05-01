# frozen_string_literal: true

RSpec.describe Ottogen::Collection do
  describe '#items' do
    it 'reads items from _<name>/' do
      in_tmp_dir do
        FileUtils.mkdir_p('_recipes')
        File.write('_recipes/pizza.adoc', "= Pizza\n")
        File.write('_recipes/bread.adoc', "= Bread\n")

        collection = described_class.from_config('recipes', 'output' => true)

        expect(collection.items.map(&:slug)).to contain_exactly('pizza', 'bread')
      end
    end

    it 'returns an empty items list when the directory is missing' do
      in_tmp_dir do
        collection = described_class.from_config('recipes', 'output' => true)

        expect(collection.items).to eq([])
      end
    end
  end

  describe '#output?' do
    it 'reflects the output: setting' do
      expect(described_class.from_config('a', 'output' => true).output?).to be true
      expect(described_class.from_config('b', 'output' => false).output?).to be false
      expect(described_class.from_config('c', {}).output?).to be false
    end
  end
end

RSpec.describe Ottogen::CollectionItem do
  describe '#url' do
    it 'is /<collection>/<slug>.html' do
      in_tmp_dir do
        FileUtils.mkdir_p('_recipes')
        File.write('_recipes/pizza.adoc', "= Pizza\n")

        item = described_class.read('_recipes/pizza.adoc', 'recipes')

        expect(item.url).to eq('/recipes/pizza.html')
      end
    end
  end

  describe '#output_path' do
    it 'is <build_dir>/<collection>/<slug>.html' do
      in_tmp_dir do
        FileUtils.mkdir_p('_recipes')
        File.write('_recipes/pizza.adoc', "= Pizza\n")

        item = described_class.read('_recipes/pizza.adoc', 'recipes')

        expect(item.output_path('_build')).to eq('_build/recipes/pizza.html')
      end
    end
  end
end
