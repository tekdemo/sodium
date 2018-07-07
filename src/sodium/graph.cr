module Sodium
  class Graph(T)
    include Iterator(T)

    # Initialize empty graph
    def initialize
      @adj = {} of T => Hash(T, Hash(Symbol, Int32))
      @node = {} of T => Hash(Symbol, Int32)

      @iter_idx = 0
    end

    # :nodoc:
    # Converts NamedTuple to Hash
    def attr_to_h(attr)
      # TODO: Fix .to_h in Crystal for NamedTuple
      if !attr.empty?
        attr.keys.map {|k| {k => attr[k]} of Symbol => Int32}.reduce {|acc, i| acc.merge(i) }
      else
        {} of Symbol => Int32
      end
    end

    # Add node to graph or update node attributes
    def add_node(n : T, **attr)
      if !@adj.has_key?(n)
        @adj[n] = {} of T => Hash(Symbol, Int32)
        @node[n] = attr_to_h(attr)
      else
        @node[n].merge!(attr_to_h(attr))
      end
    end

    # Add nodes from enumerable to graph
    def add_nodes_from(list : Enumerable(T))
      list.each { |node| add_node(node) }
    end

    # Remove node from graph
    def remove_node(n : T)
      @adj[n].keys.each {|u| @adj[u].delete(n)}
      @adj.delete(n)
      @node.delete(n)
    end

    # Remove nodes given in enumerable from graph
    def remove_nodes_from(list : Enumerable(T))
      list.each { |node| remove_node(node) }
    end
  
    # Add edge between u and v to graph
    def add_edge(u : T, v : T, **attr)
      # Add nodes
      add_node(u)
      add_node(v)
      
      if !attr.empty?
        @adj[u][v] = attr_to_h(attr)
        @adj[v][u] = attr_to_h(attr)
      else
        @adj[u][v] = {} of Symbol => Int32
        @adj[v][u] = {} of Symbol => Int32
      end
    end

    # Add edges from enumerable to graph
    def add_edges_from(list : Enumerable(Tuple(T, T)))
      list.each { |e| add_edge(e[0], e[1]) }
    end

    # Add weighted edgres from enumerable of form (u, v, weight) to graph
    def add_weighted_edges_from(list : Enumerable(Tuple(T, T, Int32)))
      list.each { |e| add_edge(e[0], e[1], weight: e[2]) }
    end

    # Remove edge from graph
    def remove_edge(u : T, v : T)
      @adj[u].delete(v)
      if u != v
        @adj[v].delete(u)
      end
    end

    # Remove edges given in enumerable from graph
    def remove_edges_from(list : Enumerable(Tuple(T, T)))
      list.each { |edge| remove_edge(edge[0], edge[1]) }
    end

    # Add star to graph (first node in array is center)
    def add_star(nodes : Array(T))
      edges = nodes[1..-1].map {|n| {nodes[0], n}}
      add_edges_from(edges)
    end

    # Add path of nodes to graph
    def add_path(nodes : Enumerable(T))
      edges = nodes.each_cons(2).map {|c| Tuple(T, T).from(c)}
      add_edges_from(edges)
    end

    # Add cycle to graph
    def add_cycle(nodes : Array(T))
      add_path(nodes)
      add_edge(nodes[-1], nodes[0])
    end

    # Clear graph
    def clear()
      @adj.clear
      @node.clear
    end

    # Return all nodes in graph
    def nodes
      @node.keys()
    end

    # Return all nodes in graph with data
    def nodes_with_data
      @node
    end

    # `Iterator`: Get next node
    def next
      # TODO: node and edge iterator
      if @iter_idx < @node.keys.size()
        if (@node.keys[@iter_idx]?)
          @iter_idx += 1
          @node.keys[@iter_idx-1]
        else
          stop
        end
      else
        stop
      end
    end

    # `Iterator`: Rewind
    def rewind
      @iter_idx = 0
      self
    end
    
    # Return all edges in graph
    def edges
      seen = Set(T).new
      arr = [] of Tuple(T, T)
      @adj.each do |k, v|
        v.each do |subk, subv|
          if !seen.includes? subk
            arr << {k, subk}
          end
        end
        seen.add k
      end
      arr
    end

    # Return associated data of specified edge
    def get_edge_data(u : T, v : T)
      first = @adj[u]?
      if first
        first.fetch(v, {} of Symbol => Int32)
      else
        {} of Symbol => Int32
      end
    end

    # Return neighbours of node
    def neighbours(node : T)
      @adj.fetch(node, {} of T => T).keys()
    end

    # Get node from graph
    def [](node : T)
      @node[node]
    end

    # Return adjacency list in order of #nodes()
    def adjacency_list()
      @adj.map {|k, v| v.keys()}
    end

    # Check if graph contains node
    def has_node?(node : T)
      @node.keys.includes?(node)
    end

    # Check if graph contains node and possibly returns object
    def []?(node : T)
      @node[node]?
    end

    # Check if graph contains edge
    def has_edge?(u : T, v : T)
      if @adj.keys.includes?(u)
        @adj[u].keys.includes?(v)
      else
        false
      end
    end

    # Return order of graph
    def order
      @node.size()
    end

    # Return number of nodes in graph
    def number_of_nodes
      @node.size()
    end

    # Return degree of node
    def degree(node : T)
      @adj[node].keys.size()
    end

    # Return number of edges
    def size
      @adj.keys.map {|k| @adj[k].keys.size() }.sum() / 2
    end

    # Return number of edges between nodes
    def number_of_edges(list : Enumerable(Tuple(T, T)))
      list.count { |e| has_edge?(e[0], e[1]) }
    end

    # Return nodes with self loop
    def nodes_with_selfloops
      @adj.keys.compact_map { |k| @adj[k][k]? ? k : nil }
    end

    # Return edges with self loops
    def selfloop_edges
      @adj.keys.compact_map { |k| @adj[k][k]? ? {k, k} : nil }
    end

    # Return self-looping edges with data
    def selfloop_edges_with_data
      @adj.keys.compact_map { |k| @adj[k][k]? ? {k, k, @adj[k][k]} : nil }
    end

    # Return number of edges with self loops
    def number_of_selfloops
      selfloop_edges.size()
    end
    
    # Return shallow copy of graph
    def copy
      self.dup
    end

    # Compute quotient graph with respect to the given partition
    #
    # The partition is given in the form of a Hash map of objects representing
    # the partition's parts to the vertices included in each part.
    #
    # ```
    # g = Sodium::Graph(Int32).new
    # g.add_edges_from([{1, 2}, {3, 4}, {5, 6}])
    # h = g / g.nodes.group_by { |n| n % 3 }
    # h.edges # => [{1, 2}, {1, 0}, {2, 0}]
    # ```
    def /(partition : Hash(T, Enumerable(T)))
      edges.reduce(self.class.new) do |g, e|
        source = target = nil
        partition.each do |repr, vs|
          source = repr if vs.includes? e[0]
          target = repr if vs.includes? e[1]
        end
        source = e[0] if source.nil?
        target = e[1] if target.nil?
        g.add_edge(source, target) unless source == target
        g
      end
    end
  end
end
