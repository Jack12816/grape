# frozen_string_literal: true

describe Grape::Middleware::Versioner::Path do
  subject { described_class.new(app, options) }

  let(:app) { ->(env) { [200, env, env[Grape::Env::API_VERSION]] } }
  let(:options) { {} }

  it 'sets the API version based on the first path' do
    expect(subject.call(Rack::PATH_INFO => '/v1/awesome').last).to eq('v1')
  end

  it 'does not cut the version out of the path' do
    expect(subject.call(Rack::PATH_INFO => '/v1/awesome')[1][Rack::PATH_INFO]).to eq('/v1/awesome')
  end

  it 'provides a nil version if no path is given' do
    expect(subject.call(Rack::PATH_INFO => '/').last).to be_nil
  end

  context 'with a pattern' do
    let(:options) { { pattern: /v./i } }

    it 'sets the version if it matches' do
      expect(subject.call(Rack::PATH_INFO => '/v1/awesome').last).to eq('v1')
    end

    it 'ignores the version if it fails to match' do
      expect(subject.call(Rack::PATH_INFO => '/awesome/radical').last).to be_nil
    end
  end

  [%w[v1 v2], %i[v1 v2], [:v1, 'v2'], ['v1', :v2]].each do |versions|
    context "with specified versions as #{versions}" do
      let(:options) { { versions: versions } }

      it 'throws an error if a non-allowed version is specified' do
        expect(catch(:error) { subject.call(Rack::PATH_INFO => '/v3/awesome') }[:status]).to eq(404)
      end

      it 'allows versions that have been specified' do
        expect(subject.call(Rack::PATH_INFO => '/v1/asoasd').last).to eq('v1')
      end
    end
  end

  context 'with prefix, but requested version is not matched' do
    let(:options) { { prefix: '/v1', pattern: /v./i } }

    it 'recognizes potential version' do
      expect(subject.call(Rack::PATH_INFO => '/v3/foo').last).to eq('v3')
    end
  end

  context 'with mount path' do
    let(:options) { { mount_path: '/mounted', versions: [:v1] } }

    it 'recognizes potential version' do
      expect(subject.call(Rack::PATH_INFO => '/mounted/v1/foo').last).to eq('v1')
    end
  end
end
