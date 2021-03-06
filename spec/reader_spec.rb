$:.unshift "."
require 'spec_helper'
require 'rdf/spec/reader'

describe "RDF::RDFa::Reader" do
  before :each do
    @reader = RDF::RDFa::Reader.new(StringIO.new("<html></html>"))
  end

  include RDF_Reader

  describe ".for" do
    formats = [
      :rdfa,
      'etc/doap.html',
      {:file_name      => 'etc/doap.html'},
      {:file_extension => 'html'},
      {:content_type   => 'text/html'},

      :xhtml,
      'etc/doap.xhtml',
      {:file_name      => 'etc/doap.xhtml'},
      {:file_extension => 'xhtml'},
      {:content_type   => 'application/xhtml+xml'},

      :svg,
      'etc/doap.svg',
      {:file_name      => 'etc/doap.svg'},
      {:file_extension => 'svg'},
      {:content_type   => 'image/svg+xml'},
    ].each do |arg|
      it "discovers with #{arg.inspect}" do
        RDF::Reader.for(arg).should == RDF::RDFa::Reader
      end
    end
  end

  context :interface do
    before(:each) do
      @sampledoc = %(<?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml"
              xmlns:dc="http://purl.org/dc/elements/1.1/">
        <head>
          <title>Test 0001</title>
        </head>
        <body>
          <p>This photo was taken by <span class="author" about="photo1.jpg" property="dc:creator">Mark Birbeck</span>.</p>
        </body>
        </html>
        )
    end

    it "should yield reader" do
      inner = double("inner")
      inner.should_receive(:called).with(RDF::RDFa::Reader)
      RDF::RDFa::Reader.new(@sampledoc) do |reader|
        inner.called(reader.class)
      end
    end

    it "should return reader" do
      RDF::RDFa::Reader.new(@sampledoc).should be_a(RDF::RDFa::Reader)
    end

    it "should yield statements" do
      inner = double("inner")
      inner.should_receive(:called).with(RDF::Statement)
      RDF::RDFa::Reader.new(@sampledoc).each_statement do |statement|
        inner.called(statement.class)
      end
    end

    it "should yield triples" do
      inner = double("inner")
      inner.should_receive(:called).with(RDF::URI, RDF::URI, RDF::Literal)
      RDF::RDFa::Reader.new(@sampledoc).each_triple do |subject, predicate, object|
        inner.called(subject.class, predicate.class, object.class)
      end
    end
    
    it "should call Proc with processor statements for :processor_callback" do
      lam = double("lambda")
      lam.should_receive(:call).at_least(1).times.with(kind_of(RDF::Statement))
      RDF::RDFa::Reader.new(@sampledoc, :processor_callback => lam).each_triple {}
    end
    
    context "rdfagraph option" do
      let(:source) do
        %(<!DOCTYPE html>
          <html>
            <span property="dc:title">Title</span>
            <span property="undefined:curie">Undefined Curie</span>
          </html>
        )
      end

      let(:output) do
        %(
          PREFIX dc: <http://purl.org/dc/terms/>
          ASK WHERE {
            ?s dc:title "Title" .
          }
        )
      end
      
      let(:processor) do
        %(
          PREFIX rdfa: <http://www.w3.org/ns/rdfa#>
          ASK WHERE {
            ?s a rdfa:Info .
          }
        )
      end

      it "generates output graph by default" do
        parse(source).should pass_query(output, :trace => @debug)
      end

      it "generates output graph with rdfagraph=output" do
        parse(source, :rdfagraph => :output).should pass_query(output, :trace => @debug)
        parse(source, :rdfagraph => :output).should_not pass_query(processor, :trace => @debug)
      end

      it "generates output graph with rdfagraph=[output]" do
        parse(source, :rdfagraph => [:output]).should pass_query(output, :trace => @debug)
      end

      it "generates output graph with rdfagraph=foo" do
        parse(source, :rdfagraph => :foo).should pass_query(output, :trace => @debug)
      end

      it "generates processor graph with rdfagraph=processor" do
        parse(source, :rdfagraph => :processor).should pass_query(processor, :trace => @debug)
        parse(source, :rdfagraph => :processor).should_not pass_query(output, :trace => @debug)
      end

      it "generates both output and processor graphs with rdfagraph=[output,processor]" do
        parse(source, :rdfagraph => [:output, :processor]).should pass_query(output, :trace => @debug)
        parse(source, :rdfagraph => [:output, :processor]).should pass_query(processor, :trace => @debug)
      end

      it "generates both output and processor graphs with rdfagraph=output,processor" do
        parse(source, :rdfagraph => "output, processor").should pass_query(output, :trace => @debug)
        parse(source, :rdfagraph => "output, processor").should pass_query(processor, :trace => @debug)
      end
    end
  end

  [:nokogiri, :rexml].each do |library|
    context library.to_s, :library => library do
      next if library == :nokogiri && RUBY_PLATFORM == 'java'
      before(:all) {@library = library}
      
      context "sanity checking" do
        it "simple doc" do
          html = %(<?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">
            <html xmlns="http://www.w3.org/1999/xhtml"
                  xmlns:dc="http://purl.org/dc/elements/1.1/">
            <head>
              <title>Test 0001</title>
            </head>
            <body>
              <p>This photo was taken by <span class="author" about="photo1.jpg" property="dc:creator">Mark Birbeck</span>.</p>
            </body>
            </html>
            )
          expected = %(
            @prefix dc: <http://purl.org/dc/elements/1.1/> .

            <photo1.jpg> dc:creator "Mark Birbeck" .
          )

          parse(html).should be_equivalent_graph(expected, :trace => @debug)
        end
      end

      context :features do
        describe "XML Literal", :not_jruby => true do
          it "rdf:XMLLiteral" do
            html = %(<?xml version="1.0" encoding="UTF-8"?>
              <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">
              <html xmlns="http://www.w3.org/1999/xhtml">
                <head><base href=""/></head>
                <body>
                  <div about="http://example/">
                    <h2 property="dc:title" datatype="rdf:XMLLiteral">E = mc<sup>2</sup>: The Most Urgent Problem of Our Time</h2>
                </div>
                </body>
              </html>
              )
            expected = %q(
              @base <http://example/> .
              @prefix dc: <http://purl.org/dc/terms/> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

              <> dc:title "E = mc<sup xmlns=\"http://www.w3.org/1999/xhtml\">2</sup>: The Most Urgent Problem of Our Time"^^rdf:XMLLiteral .
            )

            parse(html).should be_equivalent_graph(expected, :trace => @debug)
          end
        end

        describe "HTML Literal" do
          it "rdf:HTML" do
            html = %(<!DOCTYPE html>
              <html>
                <head><base href=""/></head>
                <body>
                  <div about="http://example/">
                    <h2 property="dc:title" datatype="rdf:HTML">E = mc<sup>2</sup>: The Most Urgent Problem of Our Time</h2>
                </div>
                </body>
              </html>
              )
            expected = %q(
              @base <http://example/> .
              @prefix dc: <http://purl.org/dc/terms/> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

              <> dc:title "E = mc<sup>2</sup>: The Most Urgent Problem of Our Time"^^rdf:HTML .
            )

            parse(html).should be_equivalent_graph(expected, :trace => @debug)
          end
        end

        it "bnodes" do
          html = %(<?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">
            <html xmlns="http://www.w3.org/1999/xhtml" version="XHTML+RDFa 1.1"
                  xmlns:foaf="http://xmlns.com/foaf/0.1/">
              <head>
              <title>Test 0017</title>
              </head>
              <body>
                 <p>
                      <span about="[_:a]" property="foaf:name">Manu Sporny</span>
                       <span about="[_:a]" rel="foaf:knows" resource="[_:b]">knows</span>
                       <span about="[_:b]" property="foaf:name">Ralph Swick</span>.
                    </p>
              </body>
            </html>
            )
          expected = %q(
            @base <http://example> .
            @prefix foaf: <http://xmlns.com/foaf/0.1/> .

             [ foaf:name "Manu Sporny";
               foaf:knows [ foaf:name "Ralph Swick"];
             ] .
          )

          parse(html).should be_equivalent_graph(expected, :trace => @debug)
        end

        describe "@about" do
          it "creates a statement with subject from @about" do
            html = %(
              <span about="foo" property="dc:title">Title</span>
            )
            expected = %q(
              @prefix dc: <http://purl.org/dc/terms/> .

              <foo> dc:title "Title" .
            )
            parse(html).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
          end
          
          it "creates a typed subject with @typeof" do
            html = %(
              <span about="foo" property="dc:title" typeof="rdfs:Resource">Title</span>
            )
            expected = %q(
              @prefix dc: <http://purl.org/dc/terms/> .
              @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

              <foo> a rdfs:Resource; dc:title "Title" .
            )
            parse(html).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
          end
        end

        describe "@resource" do
          it "creates a statement with object from @resource" do
            html = %(
              <div about="foo"><span resource="bar" rel="rdf:value"/></div>
            )
            expected = %q(
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              <foo> rdf:value <bar> .
            )
            parse(html).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
          end

          it "creates a type on object with @typeof" do
            html = %(
              <div about="foo"><link resource="bar" rel="rdf:value" typeof="rdfs:Resource"/></div>
            )
            expected = %q(
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
              <foo> rdf:value <bar> .
              <bar> a rdfs:Resource .
            )
            parse(html).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
          end

          it "uses @resource as subject of child elements" do
            html = %(
              <div resource="foo"><span property="dc:title">Title</span></div>
            )
            expected = RDF::Graph.new << RDF::Statement.new(RDF::URI("foo"), RDF::DC.title, "Title")
            parse(html).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
          end

          context :SafeCURIEorCURIEorIRI do
            {
              :term => [
                %(<link about="" property="rdf:value" resource="describedby"/>),
                %q(
                  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                  @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                  <> rdf:value <describedby> .
                )
              ],
              :curie => [
                %(<link about="" property="rdf:value" resource="xhv:describedby"/>),
                %q(
                  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                  @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                  <> rdf:value xhv:describedby .
                )
              ],
              :save_curie => [
                %(<link about="" property="rdf:value" resource="[xhv:describedby]"/>),
                %q(
                  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                  @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                  <> rdf:value xhv:describedby .
                )
              ],
            }.each do |test, (input, expected)|
              it "expands #{test}" do
                parse(input).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
              end
            end
          end
        end

        describe "@href" do
          it "creates a statement with object from @href" do
            html = %(
              <div about="foo"><a href="bar" rel="rdf:value"></a></div>
            )
            expected = RDF::Graph.new << RDF::Statement.new(RDF::URI("foo"), RDF.value, RDF::URI("bar"))
            parse(html).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
          end
        end

        describe "@src" do
          subject {
            %(
              <div about="foo" xmlns:dc="http://purl.org/dc/terms/">
                <img src="bar" rel="rdf:value" property="dc:title" content="Title"/>
              </div>
            )
          }
          context "RDFa 1.0" do
            it "creates a statement with subject from @src" do
              expected = RDF::Graph.new << RDF::Statement.new(RDF::URI("bar"), RDF::DC.title, "Title")
              parse(subject, :version => "rdfa1.0").should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
            end
          end
      
          context "RDFa 1.1" do
            it "creates a statement with object from @src" do
              expected = RDF::Graph.new <<
                RDF::Statement.new(RDF::URI("foo"), RDF.value, RDF::URI("bar")) <<
                RDF::Statement.new(RDF::URI("foo"), RDF::DC.title, "Title")
              parse(subject).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
            end
          end
        end

        describe "@typeof" do
          it "handles basic case" do
            html = %(<?xml version="1.0" encoding="UTF-8"?>
              <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">
              <html xmlns="http://www.w3.org/1999/xhtml" version="XHTML+RDFa 1.1"
                    xmlns:foaf="http://xmlns.com/foaf/0.1/">
                <head>
                  <title>Test 0049</title>
                </head>
                <body>
                  <div about="http://example/#me" typeof="foaf:Person">
                    <p property="foaf:name">John Doe</p>
                  </div>
                </body>
              </html>
              )
            expected = %(
              @prefix foaf: <http://xmlns.com/foaf/0.1/> .
              @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

              <http://example/#me> a foaf:Person;
                 foaf:name "John Doe" .
            )

            parse(html).should be_equivalent_graph(expected, :trace => @debug)
          end
          
          it "empty @typeof on root" do
            html = %(<html typeof=""><span property="dc:title">Title</span></html>)
            expected = RDF::Graph.new << RDF::Statement.new(RDF::URI(""), RDF::DC.title, "Title")

            parse(html).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
          end
        end

        it "html>head>base" do
          html = %(<?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">
            <html xmlns="http://www.w3.org/1999/xhtml" version="XHTML+RDFa 1.1"
                xmlns:dc="http://purl.org/dc/elements/1.1/">
             <head>
                <base href="http://example/"></base>
                <title>Test 0072</title>
             </head>
             <body>
                <p about="faq">
                   Learn more by reading the example.org
                   <span property="dc:title">Example FAQ</span>.
                </p>
             </body>
            </html>
            )
          expected = %q(
            @prefix dc: <http://purl.org/dc/elements/1.1/> .

            <http://example/faq> dc:title "Example FAQ" .
          )

          parse(html).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
        end

        describe "xml:base" do
          {
            :xml => true,
            :xhtml1 => false,
            :html4 => false,
            :html5 => false,
            :xhtml5 => true,
            :svg => true
          }.each do |hl, does|
            context "#{hl}" do
              it %(#{does ? "uses" : "does not use"} xml:base in root) do
                html = %(<div xml:base="http://example/">
                    <span property="rdf:value">Value</span>
                  </div>
                )
                expected_true = %(
                  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

                  <http://example/> rdf:value "Value" .
                )
                expected_false = %(
                  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

                  <http://example/doc_base> rdf:value "Value" .
                )
                expected = does ? expected_true : expected_false

                parse(html, :base_uri => "http://example/doc_base",
                  :version => :"rdfa1.1",
                  :host_language => hl
                ).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
              end
              
              it %(#{does ? "uses" : "does not use"} xml:base in non-root) do
                html = %(<div xml:base="http://example/">
                    <a xml:base="http://example/" property="rdf:value" href="">Value</a>
                  </div>
                )
                expected_true = %(
                  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

                  <http://example/> rdf:value <http://example/> .
                )
                expected_false = %(
                  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

                  <http://example/doc_base> rdf:value <http://example/doc_base> .
                )
                expected = does ? expected_true : expected_false

                parse(html, :base_uri => "http://example/doc_base",
                  :version => :"rdfa1.1",
                  :host_language => hl
                ).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
              end
            end
          end
        end

        describe "empty CURIE" do
          {
            "ignores about with typeof" => [
              %(<div about="[]" typeof="foaf:Person" property="foaf:name">Alex Milowski</div>),
              %(
                @prefix foaf: <http://xmlns.com/foaf/0.1/> .
                <> foaf:name "Alex Milowski" .
                [ a foaf:Person ] .
              )
            ],
            "ignores about with chaining" => [
              %(
                <div about="[]" typeof="foaf:Person">
                  <span property="foaf:name">Alex Milowski</span>
                </div>
              ),
              %(
                @prefix foaf: <http://xmlns.com/foaf/0.1/> .
                [a foaf:Person; foaf:name "Alex Milowski"] .
              )
            ],
            "ignores resource with href (rel)" => [
              %(<a href="license.xhtml" rel="license" resource="[]">The Foo Document</a>),
              %(
                @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                <> xhv:license <license.xhtml> .
              )
            ],
            "ignores resource with href (property)" => [
              %(<a href="license.xhtml" property="license" resource="[]">The Foo Document</a>),
              %(
                @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                <> xhv:license <license.xhtml> .
              )
            ],
          }.each do |name, (html,expected)|
            it name do
              parse("<html>#{html}</html>", :version => :"rdfa1.1").should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
            end
          end
        end

        context "malformed datatypes" do
          {
            "xsd:boolean" => %w(foo),
            "xsd:date" => %w(+2010-01-01Z 2010-01-01TFOO 02010-01-01 2010-1-1 0000-01-01 2011-07 2011),
            "xsd:dateTime" => %w(+2010-01-01T00:00:00Z 2010-01-01T00:00:00FOO 02010-01-01T00:00:00 2010-01-01 2010-1-1T00:00:00 0000-01-01T00:00:00 2011-07 2011),
            "xsd:decimal" => %w(12.xyz),
            "xsd:double" => %w(xy.z +1.0z),
            "xsd:integer" => %w(+1.0z foo),
            "xsd:time" => %w(+00:00:00Z -00:00:00Z 00:00 00),
          }.each do |dt, values|
            context dt do
              values.each do |value|
                before(:all) do
                  @rdfa = %(<span about="" property="rdf:value" datatype="#{dt}" content="#{value}"/>)
                  dt_uri = RDF::XSD.send(dt.split(':').last)
                  @expected = RDF::Graph.new << RDF::Statement.new(RDF::URI(""), RDF.value, RDF::Literal.new(value, :datatype => dt_uri))
                end

                context "with #{value}" do
                  it "creates triple with invalid literal" do
                    parse(@rdfa, :validate => false).should be_equivalent_graph(@expected, :trace => @debug)
                  end
            
                  it "does not create triple when validating" do
                    expect {parse(@rdfa, :validate => true)}.to raise_error(RDF::ReaderError)
                  end
                end
              end
            end
          end
        end

        context "CURIEs" do
          it "accepts a CURIE with a local part having a ':'" do
            html = %(
              <html prefix="foo: http://example/">
                <div property="foo:due:to:facebook:interpretation:of:CURIE">Value</div>
              </html>
            )
            expected = RDF::Graph.new << RDF::Statement.new(
              RDF::URI(""),
              RDF::URI("http://example/due:to:facebook:interpretation:of:CURIE"),
              "Value"
            )
            parse(html).should be_equivalent_graph(expected, :trace => @debug)
          end
        end

        context "@vocab" do
          before(:all) do
            @sampledoc = %q(
            <html>
              <head>
                <base href="http://example/"/>
              </head>
              <body>
                <div about ="#me" vocab="http://xmlns.com/foaf/0.1/" typeof="Person" >
                  <p property="name">Gregg Kellogg</p>
                </div>
              </body>
            </html>
            )
          end
      
          it "uses vocabulary when creating property IRI" do
            query = %q(
              PREFIX foaf: <http://xmlns.com/foaf/0.1/>
              ASK WHERE { <http://example/#me> a foaf:Person }
            )
            parse(@sampledoc).should pass_query(query, @debug)
          end

          it "uses vocabulary when creating type IRI" do
            query = %q(
              PREFIX foaf: <http://xmlns.com/foaf/0.1/>
              ASK WHERE { <http://example/#me> foaf:name "Gregg Kellogg" }
            )
            parse(@sampledoc).should pass_query(query, @debug)
          end

          it "adds rdfa:hasProperty triple" do
            query = %q(
              PREFIX foaf: <http://xmlns.com/foaf/0.1/>
              PREFIX rdfa: <http://www.w3.org/ns/rdfa#>
              ASK WHERE { <http://example/> rdfa:usesVocabulary foaf: }
            )
            parse(@sampledoc).should pass_query(query, @debug)
          end
          
          context "with terms" do
            [
              %q(term),
              %q(A/B),
              %q(a09b),
              %q(a_b),
              %q(a.b),
              #%q(\u002e_escaped_unicode),
            ].each do |term|
              it "accepts #{term.inspect}" do
                input = %(
                  <span vocab="http://example/" property="#{term}">Foo</span>
                )
                query = %(
                  ASK WHERE { <> <http://example/#{term}> "Foo" }
                )
                parse(input).should pass_query(query, @debug)
              end
            end

            [
              %q(prefix:suffix),
              %q(a b),
              %q(/path),
              %q(1leading_numeric),
              %q(_leading_underscore),
              %q(\u0301foo),
            ].each do |term|
              it "rejects #{term.inspect}" do
                input = %(
                  <span vocab="http://example/" property="#{term}">Foo</span>
                )
                query = %(
                  ASK WHERE { <> <http://example/#{term}> "Foo" }
                )
                begin
                  parse(input).should_not pass_query(query, @debug)
                rescue
                  # It's okay for SPARQL to throw an error
                end
              end
            end
          end
        end

        context "@inlist" do
          {
            "empty list" => [
              %q(
                <div about="">
                  <p rel="rdf:value" inlist=""/>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
            
                <> rdf:value () .
              )
            ],
            "literal" => [
              %q(
                <div about="">
                  <p property="rdf:value" inlist="">Foo</p>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
            
                <> rdf:value ("Foo") .
              )
            ],
            "IRI" => [
              %q(
                <div about="">
                  <a rel="rdf:value" inlist="" href="foo">Foo</a>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
            
                <> rdf:value (<foo>) .
              )
            ],
            "implicit list with hetrogenious membership" => [
              %q(
                <div about="">
                  <p property="rdf:value" inlist="">Foo</p>
                  <a rel="rdf:value" inlist="" href="foo">Foo</a>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
            
                <> rdf:value ("Foo" <foo>) .
              )
            ],
            "implicit list at different levels" => [
              %q(
                <div about="">
                  <p property="rdf:value" inlist="">Foo</p>
                  <strong><p property="rdf:value" inlist="">Bar</p></strong>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
            
                <> rdf:value ("Foo" "Bar") .
              )
            ],
            "property with list and literal" => [
              %q(
                <div about="">
                  <p property="rdf:value" inlist="">Foo</p>
                  <strong><p property="rdf:value" inlist="">Bar</p></strong>
                  <p property="rdf:value">Baz</p>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
            
                <> rdf:value ("Foo" "Bar"), "Baz" .
              )
            ],
            "multiple rel items" => [
              %q(
                <div about="">
                  <ol rel="rdf:value" inlist="">
                    <li><a href="foo">Foo</a></li>
                    <li><a href="bar">Bar</a></li>
                  </ol>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
            
                <> rdf:value (<foo> <bar>) .
              )
            ],
            "multiple collections" => [
              %q(
                <div>
                  <div about="foo">
                    <p property="rdf:value" inlist="">Foo</p>
                  </div>
                  <div about="foo">
                    <p property="rdf:value" inlist="">Bar</p>
                  </div>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
            
                <foo> rdf:value ("Foo"), ("Bar") .
              )
            ],
            "confusion between multiple implicit collections (resource)" => [
              %q(
                <div about="">
                  <p property="rdf:value" inlist="">Foo</p>
                  <span rel="rdf:inlist" resource="res">
                    <p property="rdf:value" inlist="">Bar</p>
                  </span>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
            
                <> rdf:value ("Foo"); rdf:inlist <res> .
                <res> rdf:value ("Bar") .
              )
            ],
            "confusion between multiple implicit collections (about)" => [
              %q(
                <div about="">
                  <p property="rdf:value" inlist="">Foo</p>
                  <span rel="rdf:inlist">
                    <p about="res" property="rdf:value" inlist="">Bar</p>
                  </span>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
            
                <> rdf:value ("Foo"); rdf:inlist <res> .
                <res> rdf:value ("Bar") .
              )
            ],
          }.each do |test, (input, expected)|
            it test do
              parse(input).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
            end
          end
        end

        context "@property" do
          {
            "with text content" => [
              %q(
                <div about="">
                  <p property="rdf:value">Foo</p>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "Foo" .
              )
            ],
            "with @lang" => [
              %q(
                <div about="">
                  <p property="rdf:value" lang="en">Foo</p>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "Foo"@en .
              )
            ],
            "with @xml:lang" => [
              %q(
                <div about="">
                  <p property="rdf:value" xml:lang="en">Foo</p>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "Foo"@en .
              )
            ],
            "with @content" => [
              %q(
                <div about="">
                  <title property="rdf:value" content="Foo">Bar</title>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "Foo" .
              )
            ],
            "with @href" => [
              %q(
                <div about="">
                  <a property="rdf:value" href="#foo">Bar</a>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value <#foo> .
              )
            ],
            "with @src" => [
              %q(
                <div about="">
                  <img property="rdf:value" src="#foo"/>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value <#foo> .
              )
            ],
            "with <time>=xsd:time" => [
              %q(
                <div about="">
                  <time property="rdf:value">00:00:00Z</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "00:00:00Z"^^<http://www.w3.org/2001/XMLSchema#time> .
              )
            ],
            "with @datetime=xsd:date" => [
              %q(
                <div about="">
                  <time property="rdf:value" datetime="2011-06-28Z">28 June 2011</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "2011-06-28Z"^^<http://www.w3.org/2001/XMLSchema#date> .
              )
            ],
            "with @datetime=xsd:time" => [
              %q(
                <div about="">
                  <time property="rdf:value" datetime="00:00:00Z">midnight</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "00:00:00Z"^^<http://www.w3.org/2001/XMLSchema#time> .
              )
            ],
            "with @datetime=xsd:dateTime" => [
              %q(
                <div about="">
                  <time property="rdf:value" datetime="2011-06-28T00:00:00Z">28 June 2011 at midnight</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "2011-06-28T00:00:00Z"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
              )
            ],
            "with @datetime=xsd:dateTime with TZ offset" => [
              %q(
                <div about="">
                  <time property="rdf:value" datetime="2011-06-28T00:00:00-08:00">28 June 2011 at midnight in San Francisco</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "2011-06-28T00:00:00-08:00"^^<http://www.w3.org/2001/XMLSchema#dateTime> .
              )
            ],
            "with @datetime=xsd:dateTime with @datatype" => [
              %q(
                <div about="">
                  <time property="rdf:value" datetime="2012-03-18T00:00:00Z" datatype="xsd:string"> March 2012 at midnight in San Francisco</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
          
                <> rdf:value "2012-03-18T00:00:00Z"^^xsd:string .
              )
            ],
            "with @datetime=xsd:gYear" => [
              %q(
                <div about="">
                  <time property="rdf:value" datetime="2011">2011</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "2011"^^<http://www.w3.org/2001/XMLSchema#gYear> .
              )
            ],
            "with @datetime=xsd:gYearMonth" => [
              %q(
                <div about="">
                  <time property="rdf:value" datetime="2011-06">2011</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "2011-06"^^<http://www.w3.org/2001/XMLSchema#gYearMonth> .
              )
            ],
            "with @datetime=xsd:duration" => [
              %q(
                <div about="">
                  <time property="rdf:value" datetime="P2011Y06M28DT00H00M00S">2011 years 6 months 28 days</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "P2011Y06M28DT00H00M00S"^^<http://www.w3.org/2001/XMLSchema#duration> .
              )
            ],
            "with @datetime=plain" => [
              %q(
                <div about="">
                  <time property="rdf:value" datetime="foo">Foo</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "foo" .
              )
            ],
            "with @datetime=plain with @lang" => [
              %q(
                <div about="">
                  <time property="rdf:value" lang="en" datetime="D-Day">Foo</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value "D-Day"@en .
              )
            ],
            "with @datetime and @content" => [
              %q(
                <div about="">
                  <time property="rdf:value" datetime="2012-03-18" content="this">18 March 2012</time>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
          
                <> rdf:value "this" .
              )
            ],
            "with @resource" => [
              %q(
                <div about="">
                  <p property="rdf:value" resource="#foo">Bar</p>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value <#foo> .
              )
            ],
            "with @typeof" => [
              %q(
                <div about="">
                  <div property="rdf:value" typeof="">Bar</div>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value [] .
              )
            ],
            "with @about" => [
              %q(
                <div about="">
                  <div property="rdf:value" about="#foo"> <p property="rdf:value">Bar</p> </div>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <#foo> rdf:value " Bar ", "Bar" .
              )
            ],
            "@href and @property no-chaining" => [
              %q(
                <div about="">
                  <a property="rdf:value" href="#foo">
                    <span property="rdf:value">Bar</span>
                  </a>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          
                <> rdf:value <#foo>, "Bar" .
              )
            ],
            "@href, @typeof and @property chaining" => [
              %q(
                <div typeof="foaf:Person" about="http://greggkellogg.net/foaf#me">
                  <p property="foaf:name">Gregg Kellogg</p>
                  <p property="foaf:knows" typeof="foaf:Person" href="http://manu.sporny.org/#this">
                    <span property="foaf:name">Manu Sporny</span>
                  </p>
                </div>
              ),
              %q(
                @prefix foaf: <http://xmlns.com/foaf/0.1/> .
                <http://greggkellogg.net/foaf#me> a foaf:Person;
                  foaf:name "Gregg Kellogg";
                  foaf:knows <http://manu.sporny.org/#this> .
                <http://manu.sporny.org/#this> a foaf:Person;
                  foaf:name "Manu Sporny" .
              )
            ],
            "@property with @href in a list" => [
              %q(
                <div about="http://example">
                  <a inlist="" property="rdf:value" href="http://example#foo"></a>
                  <a inlist="" property="rdf:value" href="http://example#bar"></a>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                <http://example> rdf:value ( <http://example#foo> <http://example#bar> ).
              )
            ],
            "@property and @rel with @href in a list" => [
              %q(
                <div about="http://example">
                  <a inlist="" property="rdf:value" href="http://example#foo"></a>
                  <a inlist="" rel="rdf:value" href="http://example#bar"></a>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                <http://example> rdf:value ( <http://example#foo> <http://example#bar> ).
              )
            ],
            #"@property and @typeof and incomplete triples" => [
            #  %q(
            #    <div about="http://greggkellogg.net/foaf#me" rel="foaf:knows">
            #      <span property="foaf:name" typeof="foaf:Person">Ivan Herman</span>
            #    </div>
            #  ),
            #  %q(
            #    @prefix foaf: <http://xmlns.com/foaf/0.1/> .
            #    <http://greggkellogg.net/foaf#me> foaf:knows [
            #      foaf:name "Ivan Herman"
            #    ].
            #    [ a foaf:Person ] .
            #  )
            #],
            #"@property, @href and @typeof and incomplete triples" => [
            #  %q(
            #    <div about="http://greggkellogg.net/foaf#me" rel="foaf:knows">
            #      <a href="http://www.ivan-herman.net/foaf#me" property="foaf:name" typeof="foaf:Person">Ivan Herman</a>
            #    </div>
            #  ),
            #  %q(
            #    @prefix foaf: <http://xmlns.com/foaf/0.1/> .
            #    <http://greggkellogg.net/foaf#me> foaf:knows [ foaf:name "Ivan Herman"] .
            #    <http://www.ivan-herman.net/foaf#me> a foaf:Person .
            #  )
            #],
            "@property, @href and @datatype" => [
              %q(
                <a href="http://example/" property="rdf:value" datatype="">value</a>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                <http://example/> rdf:value "value" .
              )
            ],
            "@property, @datatype and @language" => [
              %q(
                <div about="http://example/">
                  <span property="rdf:value" lang="en" datatype="xsd:date">value</span>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
                <http://example/> rdf:value "value"^^xsd:date .
              )
            ],
            "@property, @content, @datatype and @language" => [
              %q(
                <div about="http://example/">
                  <span property="rdf:value" lang="en" datatype="xsd:date" content="value">not this</span>
                </div>
              ),
              %q(
                @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
                <http://example/> rdf:value "value"^^xsd:date .
              )
            ],
          }.each do |test, (input, expected)|
            it test do
              parse(input).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
            end
          end
        end

        context "with @rel/@rev" do
          {
            "with CURIE" => [
              %q(<a about="" property="rdf:value" rel="xhv:license" href="http://example/">Foo</a>),
              %q(<> rdf:value "Foo"; xhv:license <http://example/> .),
              %q(<> rdf:value "Foo"; xhv:license <http://example/> .)
            ],
            "with Term" => [
              %q(<a about="" property="rdf:value" rel="license" href="http://example/">Foo</a>),
              %q(<> rdf:value "Foo"; xhv:license <http://example/> .),
              %q(<> rdf:value <http://example/> .)
            ],
            "with Term and CURIE" => [
              %q(<a about="" property="rdf:value" rel="license cc:license" href="http://example/">Foo</a>),
              %q(<> rdf:value "Foo"; cc:license <http://example/>; xhv:license <http://example/> .),
              %q(<> rdf:value "Foo"; cc:license <http://example/> .),
            ],
          }.each do |test, (input, expected1, expected5)|
            context test do
              it "xhtml1" do
                expected1 = %(
                  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                  @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                  @prefix cc: <http://creativecommons.org/ns#> .
                ) + expected1
                parse(input, :host_language => :xhtml1).should be_equivalent_graph(expected1, :trace => @debug, :format => :ttl)
              end
            
              it "xhtml5" do
                expected5 = %(
                  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
                  @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                  @prefix cc: <http://creativecommons.org/ns#> .
                ) + expected5
                parse(input, :host_language => :xhtml5).should be_equivalent_graph(expected5, :trace => @debug, :format => :ttl)
              end
            end
          end
        end
        
        context "@role" do
          {
            "with @id" => [
              %(
                <div id="heading1" role="heading">
                  <p>Some contents that are a header</p>
                </div>
              ),
              %(
                @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                <#heading1> xhv:role xhv:heading.
              )
            ],
            "no @id" => [
              %(
                <div role="heading">
                  <p>Some contents that are a header</p>
                </div>
              ),
              %(
                @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                [xhv:role xhv:heading].
              )
            ],
            "@id and IRI object" => [
              %(
                <div id="therole" role="http://example/roles/somerole">
                  <p>Some contents that are a header</p>
                </div>
              ),
              %(
                @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                <#therole> xhv:role <http://example/roles/somerole>.
              )
            ],
            "@id and CURIE object" => [
              %(
                <div prefix="ex: http://example/roles/"
                     id="therole"
                     role="ex:somerole">
                  <p>Some contents that are a header</p>
                </div>
              ),
              %(
                @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                <#therole> xhv:role <http://example/roles/somerole>.
              )
            ],
            "multiple values" => [
              %(
                <div prefix="ex: http://example/roles/"
                     id="therole"
                     role="ex:somerole someOtherRole http://example/alternate/role noprefix:final">
                  <p>Some contents that are a header</p>
                </div>
              ),
              %(
                @prefix xhv: <http://www.w3.org/1999/xhtml/vocab#> .
                <#therole> xhv:role <http://example/roles/somerole>,
                  xhv:someOtherRole,
                  <http://example/alternate/role>,
                  <noprefix:final>.
              )
            ],
          }.each do |title, (input, expected)|
            it title do
              parse(input).should be_equivalent_graph(expected, :trace => @debug, :format => :ttl)
            end
          end
        end
      end

      context "problematic examples" do
        {
          "Jen's Ice Cream example" => [
            %q(<root><div vocab="#" typeof="">
              <p>Flavors in my favorite ice cream:</p>
              <div rel="flavor">
                <ul vocab="http://www.w3.org/1999/02/22-rdf-syntax-ns#" typeof="">
                  <li property="first">Lemon sorbet</li>
                  <li rel="rest">
                    <span typeof="">
                      <span property="first">Apricot sorbet</span>
                    <span rel="rest" resource="rdf:nil"></span>
                  </span>
                  </li>
                </ul>
              </div>
            </div></root>),
            %q(
            <> <http://www.w3.org/ns/rdfa#usesVocabulary> <#>, <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
            _:a <#flavor> ("Lemon sorbet" "Apricot sorbet") .
            )
          ],
          "schema.org Event with @property" => [
            %q(
              <div>
                <div vocab="http://schema.org/" typeof="Event">
                  <a property="url" href="nba-miami-philidelphia-game3.html">
                    <span property="description">
                      NBA Eastern Conference First Round Playoff Tickets:
                      Miami Heat at Philadelphia 76ers - Game 3 (Home Game 1)
                    </span>
                  </a>
                </div>
              </div>
            ),
            %q(
              @prefix schema: <http://schema.org/> .
              <> <http://www.w3.org/ns/rdfa#usesVocabulary> <http://schema.org/> .
              [ a schema:Event;
                schema:url <nba-miami-philidelphia-game3.html>;
                schema:description """
                      NBA Eastern Conference First Round Playoff Tickets:
                      Miami Heat at Philadelphia 76ers - Game 3 (Home Game 1)
                    """ ] .
            )
          ],
          "schema.org Event with @property and @typeof chain" => [
            %q(
              <div>
                <div vocab="http://schema.org/" typeof="Event">
                  <div property="offers" typeof="AggregateOffer">
                    Priced from: <span property="lowPrice">$35</span>
                    <span property="offerCount">1,938</span> tickets left
                  </div>
                </div>
              </div>
            ),
            %q(
              @prefix schema: <http://schema.org/> .
              <> <http://www.w3.org/ns/rdfa#usesVocabulary> <http://schema.org/> .
              [ a schema:Event;
                schema:offers [
                  a schema:AggregateOffer;
                  schema:lowPrice "$35";
                  schema:offerCount "1,938"
                ]
              ] .
            )
          ],
          "drupal confused @property with hanging @rel" => [
            %q(
              <li rel="dc:subject">
                  <a property="rdfs:label skos:prefLabel"
                     typeof="skos:Concept"
                     href="/plain/?q=taxonomy/term/1"
                  >xy</a>
              </li>
            ),
            %q(
              @prefix dc: <http://purl.org/dc/terms/> .
              @prefix skos: <http://www.w3.org/2004/02/skos/core#> .
              @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
              <> dc:subject [ rdfs:label </plain/?q=taxonomy/term/1>;
                         skos:prefLabel </plain/?q=taxonomy/term/1> ] .

              </plain/?q=taxonomy/term/1> a skos:Concept .
            )
          ],
          "bbc programs @rel=role with rfds:label" => [
            %q(
              <dt rel="po:role" class="role" prefix="po: http://example/">
                <span typeof="po:Role" property="rdfs:label">Director</span>
              </dt>
            ),
            %q(
              @prefix po: <http://example/> .
              @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

              <> po:role [ rdfs:label [ a po:Role ] ] .
            )
          ],
        }.each do |title, (html, ttl)|
          it "parses #{title}" do
            g_ttl = RDF::Graph.new << RDF::Turtle::Reader.new(ttl)
            parse(html, :validate => false).should be_equivalent_graph(g_ttl, :trace => @debug, :format => :ttl)
          end
        end
      end

      context "SVG metadata", :pending => (library == :rexml) do
        it "extracts RDF/XML from <metadata> element" do
          svg = %(<?xml version="1.0" encoding="UTF-8"?>
            <svg width="12cm" height="4cm" viewBox="0 0 1200 400"
            xmlns:dc="http://purl.org/dc/terms/"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            xml:base="http://example.net/"
            xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="tiny">
              <desc property="dc:description">A yellow rectangle with sharp corners.</desc>
              <metadata>
                <rdf:RDF>
                  <rdf:Description rdf:about="">
                    <dc:title>Test 0304</dc:title>
                  </rdf:Description>
                </rdf:RDF>
              </metadata>
              <!-- Show outline of canvas using 'rect' element -->
              <rect x="1" y="1" width="1198" height="398"
                    fill="none" stroke="blue" stroke-width="2"/>
              <rect x="400" y="100" width="400" height="200"
                    fill="yellow" stroke="navy" stroke-width="10"  />
            </svg>
          )
          query = %(
            ASK WHERE {
            	<http://example.net/> <http://purl.org/dc/terms/title> "Test 0304" .
            	<http://example.net/> <http://purl.org/dc/terms/description> "A yellow rectangle with sharp corners." .
            }
          )
          parse(svg).should pass_query(query, :trace => @debug)
        end
      end
      
      context "script" do
        {
          "text/turtle" => [
            %q(
              <script type="text/turtle">
              # <![CDATA[
              @prefix dc: <http://purl.org/dc/terms/> .
              @prefix frbr: <http://purl.org/vocab/frbr/core#> .

              <http://books.example.com/works/45U8QJGZSQKDH8N> a frbr:Work ;
                   dc:creator "Wil Wheaton"@en ;
                   dc:title "Just a Geek"@en ;
                   frbr:realization <http://books.example.com/products/9780596007683.BOOK>,
                       <http://books.example.com/products/9780596802189.EBOOK> .

              <http://books.example.com/products/9780596007683.BOOK> a frbr:Expression ;
                   dc:type <http://books.example.com/product-types/BOOK> .

              <http://books.example.com/products/9780596802189.EBOOK> a frbr:Expression ;
                   dc:type <http://books.example.com/product-types/EBOOK> .
              # ]]>
              </script>
            ),
            %q(
              @prefix dc: <http://purl.org/dc/terms/> .
              @prefix frbr: <http://purl.org/vocab/frbr/core#> .

              <http://books.example.com/works/45U8QJGZSQKDH8N> a frbr:Work ;
                   dc:creator "Wil Wheaton"@en ;
                   dc:title "Just a Geek"@en ;
                   frbr:realization <http://books.example.com/products/9780596007683.BOOK>,
                       <http://books.example.com/products/9780596802189.EBOOK> .

              <http://books.example.com/products/9780596007683.BOOK> a frbr:Expression ;
                   dc:type <http://books.example.com/product-types/BOOK> .

              <http://books.example.com/products/9780596802189.EBOOK> a frbr:Expression ;
                   dc:type <http://books.example.com/product-types/EBOOK> .
            )
          ],
          "text/ntriples" => [
            %q(
              <script type="text/turtle">
              # <![CDATA[
              <http://one.example/subject1> <http://one.example/predicate1> <http://one.example/object1> . # comments here
              # or on a line by themselves
              _:subject1 <http://an.example/predicate1> "object1" .
              _:subject2 <http://an.example/predicate2> "object2" .
              # ]]>
              </script>
            ),
            %q(
              <http://one.example/subject1> <http://one.example/predicate1> <http://one.example/object1> . # comments here
              # or on a line by themselves
              _:subject1 <http://an.example/predicate1> "object1" .
              _:subject2 <http://an.example/predicate2> "object2" .
            )
          ],
          "text/turtle with @id" => [
            %q(
              <script type="text/turtle" id="graph1"><![CDATA[
                 @prefix foo:  <http://example/xyz#> .
                 @prefix gr:   <http://purl.org/goodrelations/v1#> .
                 @prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
                 @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

                 foo:myCompany
                   a gr:BusinessEntity ;
                   rdfs:seeAlso <http://example/xyz> ;
                   gr:hasLegalName "Hepp Industries Ltd."^^xsd:string .
              ]]></script>
            ),
            %q(
              @prefix foo:  <http://example/xyz#> .
              @prefix gr:   <http://purl.org/goodrelations/v1#> .
              @prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
              @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

              foo:myCompany
                a gr:BusinessEntity ;
                rdfs:seeAlso <http://example/xyz> ;
                gr:hasLegalName "Hepp Industries Ltd."^^xsd:string .
            )
          ]
        }.each do |title, (input,result)|
          it title do
            parse(input).should be_equivalent_graph(result, :base_uri => "http://example/", :trace => @debug)
          end
        end
      end

      it "extracts microdata" do
        html = %(
          <html>
            <head>
              <title>Test 001</title>
            </head>
            <body>
              <p itemscope='true' itemtype="http://schema.org/Person">
                This test created by
                <span itemprop="name">Gregg Kellogg</span>.
              </p>
            </body>
          </html>
        )
        ttl = %(
          @prefix md: <http://www.w3.org/ns/md#> .
          @prefix rdfa: <http://www.w3.org/ns/rdfa#> .
          @prefix schema: <http://schema.org/> .

          <> md:item ([ a schema:Person; schema:name "Gregg Kellogg"]);
             rdfa:usesVocabulary schema: .
        )
        parse(html).should be_equivalent_graph(ttl, :trace => @debug)
      end

      context :rdfagraph do
        it "generates rdfa:Error on malformed content" do
          html = %(<!DOCTYPE html>
            <div Invalid markup
          )
          query = %(
            PREFIX dc: <http://purl.org/dc/terms/>
            PREFIX rdfa: <http://www.w3.org/ns/rdfa#>
            PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
            ASK WHERE {
              ?s a rdfa:Error;
                 dc:date ?date;
                 dc:description ?description .
              FILTER (datatype(?date) = xsd:date)
            }
          )
          parse(html, :rdfagraph => :processor).should pass_query(query, :trace => @debug)
        end
        
        it "generates rdfa:UnresolvedCURIE on missing CURIE definition" do
          html = %(<!DOCTYPE html>
            <div property="rdf:value" resource="[undefined:curie]">Undefined Curie</div>
          )
          query = %(
            PREFIX dc: <http://purl.org/dc/terms/>
            PREFIX rdfa: <http://www.w3.org/ns/rdfa#>
            PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
            ASK WHERE {
              ?s a rdfa:UnresolvedCURIE;
                 dc:date ?date;
                 dc:description ?description .
              FILTER (datatype(?date) = xsd:date)
            }
          )
          parse(html, :rdfagraph => :processor).should pass_query(query, :trace => @debug)
        end
        
        %w(
          \x01foo
          foo\x01
          $foo
        ).each do |prefix|
          it "generates rdfa:UnresolvedCURIE on malformed CURIE prefix #{prefix.inspect}" do
            html = %(<!DOCTYPE html>
              <div prefix="#{prefix}: http://example/"
                   property="rdf:value"
                   resource="[#{prefix}:malformed]">
                Malformed Prefix
              </div>
            )
            query = %(
              PREFIX dc: <http://purl.org/dc/terms/>
              PREFIX rdfa: <http://www.w3.org/ns/rdfa#>
              PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
              ASK WHERE {
                ?s a rdfa:UnresolvedCURIE;
                   dc:date ?date;
                   dc:description ?description .
                FILTER (datatype(?date) = xsd:date)
              }
            )
            parse(html, :rdfagraph => :processor).should pass_query(query, :trace => @debug)
          end
        end
        
        it "generates rdfa:UnresolvedTerm on missing Term definition" do
          html = %(<!DOCTYPE html>
            <div property="undefined_term">Undefined Term</div>
          )
          query = %(
            PREFIX dc: <http://purl.org/dc/terms/>
            PREFIX rdfa: <http://www.w3.org/ns/rdfa#>
            PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
            ASK WHERE {
              ?s a rdfa:UnresolvedTerm;
                 dc:date ?date;
                 dc:description ?description .
              FILTER (datatype(?date) = xsd:date)
            }
          )
          parse(html, :rdfagraph => :processor).should pass_query(query, :trace => @debug)
        end
      end

      context :validation do
        it "needs some examples", :pending => true
      end
    end
  end

  def parse(input, options = {})
    @debug = options[:debug] || []
    graph = RDF::Graph.new
    RDF::RDFa::Reader.new(input, options.merge(:debug => @debug, :library => @library)).each do |statement|
      graph << statement rescue fail "SPEC: #{$!}"
    end
    graph
  end

end
