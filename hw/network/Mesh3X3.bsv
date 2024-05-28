import NetworkTypes::*;
import Vector::*;
import Router::*;
import FIFOF::*;
import SpecialFIFOs::*;
import MessageTypes::*;
import RoutingTypes::*;

interface DataLink;
    method ActionValue#(Flit)         getFlit;
    method Action                     putFlit(Flit flit);
endinterface

interface Mesh3X3;
    interface Vector#(9, DataLink)    dataLinks;
    method Bool getNoCSync();
endinterface

module mkMesh3X3 (Mesh3X3);

    Router router_0_0   <-  mkRouter (0, 0);
    Router router_1_0   <-  mkRouter (1, 0);
    Router router_2_0   <-  mkRouter (2, 0);

    Router router_0_1   <-  mkRouter (0, 1);
    Router router_1_1   <-  mkRouter (1, 1);
    Router router_2_1   <-  mkRouter (2, 1);

    Router router_0_2   <-  mkRouter (0, 2);
    Router router_1_2   <-  mkRouter (1, 2);
    Router router_2_2   <-  mkRouter (2, 2);

    Vector#(9, DataLink) dataLinksDummy;
    dataLinksDummy[0] = interface DataLink
        method ActionValue#(Flit) getFlit;
            let f <- router_0_0.dataLinks[4].getFlit();
            return f;
        endmethod

        method Action putFlit (Flit flit);
            router_0_0.dataLinks[4].putFlit(flit);
        endmethod
    endinterface;

    dataLinksDummy[1] = interface DataLink
        method ActionValue#(Flit) getFlit;
            let f <- router_1_0.dataLinks[4].getFlit();
            return f;
        endmethod

        method Action putFlit (Flit flit);
            router_1_0.dataLinks[4].putFlit(flit);
        endmethod
    endinterface;

    dataLinksDummy[2] = interface DataLink
        method ActionValue#(Flit) getFlit;
            let f <- router_2_0.dataLinks[4].getFlit();
            return f;
        endmethod

        method Action putFlit (Flit flit);
            router_2_0.dataLinks[4].putFlit(flit);
        endmethod
    endinterface;



    dataLinksDummy[3] = interface DataLink
        method ActionValue#(Flit) getFlit;
            let f <- router_0_1.dataLinks[4].getFlit();
            return f;
        endmethod

        method Action putFlit (Flit flit);
            router_0_1.dataLinks[4].putFlit(flit);
        endmethod
    endinterface;

    dataLinksDummy[4] = interface DataLink
        method ActionValue#(Flit) getFlit;
            let f <- router_1_1.dataLinks[4].getFlit();
            return f;
        endmethod

        method Action putFlit (Flit flit);
            router_1_1.dataLinks[4].putFlit(flit);
        endmethod
    endinterface;

    dataLinksDummy[5] = interface DataLink
        method ActionValue#(Flit) getFlit;
            let f <- router_2_1.dataLinks[4].getFlit();
            return f;
        endmethod

        method Action putFlit (Flit flit);
            router_2_1.dataLinks[4].putFlit(flit);
        endmethod
    endinterface;



    dataLinksDummy[6] = interface DataLink
        method ActionValue#(Flit) getFlit;
            let f <- router_0_2.dataLinks[4].getFlit();
            return f;
        endmethod

        method Action putFlit (Flit flit);
            router_0_2.dataLinks[4].putFlit(flit);
        endmethod
    endinterface;

    dataLinksDummy[7] = interface DataLink
        method ActionValue#(Flit) getFlit;
            let f <- router_1_2.dataLinks[4].getFlit();
            return f;
        endmethod

        method Action putFlit (Flit flit);
            router_1_2.dataLinks[4].putFlit(flit);
        endmethod
    endinterface;

    dataLinksDummy[8] = interface DataLink
        method ActionValue#(Flit) getFlit;
            let f <- router_2_2.dataLinks[4].getFlit();
            return f;
        endmethod

        method Action putFlit (Flit flit);
            router_2_2.dataLinks[4].putFlit(flit);
        endmethod
    endinterface;

    interface dataLinks = dataLinksDummy;
    
    method Bool getNoCSync();
    	return		router_0_0.getRouterSync() &&
    			router_1_0.getRouterSync() && 
    			router_2_0.getRouterSync() &&
    			
    			router_0_1.getRouterSync() &&
    			router_1_1.getRouterSync() &&
    			router_2_1.getRouterSync() &&
    			
    			router_0_2.getRouterSync() &&
    			router_1_2.getRouterSync() &&
    			router_2_2.getRouterSync();
    endmethod

endmodule
