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

interface MeshNxN#(numeric type n);
    interface Vector#(TMul#(n,n), DataLink) dataLinks;
    method Bool getNoCSync();
endinterface

module mkMeshNxN(MeshNxN#(n));
    module mkRouterN#(Integer m)(Router);
        Integer rY = m/valueOf(n);
        Integer rX = m%valueOf(n);
        Router r <- mkRouter (fromInteger(rX), fromInteger(rY));
        return r;
    endmodule

    Vector#(TMul#(n,n), Router) routers <- genWithM(mkRouterN);
    Vector#(TMul#(n,n), DataLink) dataLinksDummy;

 
    // Routers are laid out as follows:
    //   
    //   0 - 1 - 2  |
    //   |   |   |  |
    //   3 - 4 - 5  Y
    //   |   |   |  |
    //   6 - 7 - 8  |
    //   
    //   --- X ---
    //   
    // assuming n = 3

    for (Integer i = 0; i < valueOf(n) - 1; i = i + 1) begin
        for (Integer j = 0; j < valueOf(n); j = j + 1) begin
            rule southboundConnection;
                let fromIdx = i*valueOf(n) + j;
                let toIdx = (i+1)*valueOf(n) + j;
                let f <- routers[fromIdx].dataLinks[2].getFlit();
                routers[toIdx].dataLinks[0].putFlit(f);
            endrule
            rule northboundConnection;
                let fromIdx = (i+1)*valueOf(n) + j;
                let toIdx = i*valueOf(n) + j;
                let f <- routers[fromIdx].dataLinks[0].getFlit();
                routers[toIdx].dataLinks[2].putFlit(f);
            endrule
            rule eastboundConnection;
                let fromIdx = j*valueOf(n) + i;
                let toIdx = j*valueOf(n) + i+1;
                let f <- routers[fromIdx].dataLinks[1].getFlit();
                routers[toIdx].dataLinks[3].putFlit(f);
            endrule
            rule westboundConnection;
                let fromIdx = j*valueOf(n) + i+1;
                let toIdx = j*valueOf(n) + i;
                let f <- routers[fromIdx].dataLinks[3].getFlit();
                routers[toIdx].dataLinks[1].putFlit(f);
            endrule
        end
    end

    for (Integer i = 0; i < valueOf(n); i = i + 1) begin
        for (Integer j = 0; j < valueOf(n); j = j + 1) begin
            let idx = i*valueOf(n) + j;
            dataLinksDummy[idx] = interface DataLink
                method ActionValue#(Flit) getFlit;
                    let f <- routers[idx].dataLinks[4].getFlit();
                    return f;
                endmethod

                method Action putFlit (Flit flit);
                    routers[idx].dataLinks[4].putFlit(flit);
                endmethod
            endinterface;
        end
    end

    method Bool getNoCSync();
        Bool sync = True;
        for (Integer i = 0; i < valueOf(n); i = i + 1) begin
            for (Integer j = 0; j < valueOf(n); j = j + 1) begin
                let idx = i*valueOf(n) + j;
                sync = sync && routers[idx].getRouterSync();
            end
        end
    	return sync;
    endmethod

    interface dataLinks = dataLinksDummy;


endmodule