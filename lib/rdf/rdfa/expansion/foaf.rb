# This file is automatically generated by ./script/intern_vocabulary
# RDFa vocabulary for http://xmlns.com/foaf/0.1/ loaded from http://xmlns.com/foaf/0.1/index.rdf
require 'rdf/rdfa/expansion'

module RDF::RDFa::Expansion
  [
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/Person'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subClassOf'), RDF::URI('http://xmlns.com/foaf/0.1/Agent'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/Person'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subClassOf'), RDF::URI('http://www.w3.org/2000/10/swap/pim/contact#Person'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/Person'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subClassOf'), RDF::URI('http://www.w3.org/2003/01/geo/wgs84_pos#SpatialThing'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/Organization'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subClassOf'), RDF::URI('http://xmlns.com/foaf/0.1/Agent'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/Group'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subClassOf'), RDF::URI('http://xmlns.com/foaf/0.1/Agent'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/Image'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subClassOf'), RDF::URI('http://xmlns.com/foaf/0.1/Document'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/PersonalProfileDocument'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subClassOf'), RDF::URI('http://xmlns.com/foaf/0.1/Document'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/OnlineAccount'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subClassOf'), RDF::URI('http://www.w3.org/2002/07/owl#Thing'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/OnlineGamingAccount'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subClassOf'), RDF::URI('http://xmlns.com/foaf/0.1/OnlineAccount'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/OnlineEcommerceAccount'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subClassOf'), RDF::URI('http://xmlns.com/foaf/0.1/OnlineAccount'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/OnlineChatAccount'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subClassOf'), RDF::URI('http://xmlns.com/foaf/0.1/OnlineAccount'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/aimChatID'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/nick'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/skypeID'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/nick'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/icqChatID'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/nick'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/yahooChatID'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/nick'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/msnChatID'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/nick'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/name'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#label'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/homepage'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/page'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/homepage'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/isPrimaryTopicOf'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/weblog'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/page'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/openid'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/isPrimaryTopicOf'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/tipjar'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/page'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/img'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/depiction'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
    RDF::Statement.new(RDF::URI('http://xmlns.com/foaf/0.1/isPrimaryTopicOf'), RDF::URI('http://www.w3.org/2000/01/rdf-schema#subPropertyOf'), RDF::URI('http://xmlns.com/foaf/0.1/page'), :context => RDF::URI('http://xmlns.com/foaf/0.1/')),
  ].each {|st| COOKED_VOCAB_STATEMENTS << st }
end
