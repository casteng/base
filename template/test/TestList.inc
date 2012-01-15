// Polymorfic code for list interface testing
// Coll should be an instance of a list like collection
  cnt := 0;
  Rnd.InitSequence(1, 0);
  for i := 0 to CollElCnt-1 do begin
    t := Rnd.RndI(CollElCnt);
    Coll.Add(t);
    Inc(cnt);
    Check(Coll.Contains(t), 'TestList: Conntains failed');
  end;

  Rnd.InitSequence(1, 0);
  Coll.ForEach(ForCollEl, nil);

  for i := 0 to CollElCnt div 2-1 do begin
    t := Rnd.RndI(CollElCnt);
    while Coll.Remove(t) do Dec(cnt);
    Check(not Coll.Contains(t), 'TestList: Not conntains failed');
  end;

  for i := 0 to CollElCnt div 2-1 do begin
    t := Rnd.RndI(Coll.Count);
    Coll.Put(i, CollElCnt);
    Check(Coll.Get(i) = CollElCnt, 'TestList: Put/Get failed');
    Coll.Insert(t, CollElCnt+1);
    Check((Coll.Get(t) = CollElCnt+1) and Coll.Contains(CollElCnt+1), 'TestList: Conntains inserted failed');
    Coll.RemoveBy(t);
    Check(not Coll.Contains(CollElCnt+1), 'TestList: Not conntains removed failed');
  end;

  Check(Coll.Count = cnt, 'TestList: Count failed');

  Coll.Clear;
  Check(Coll.IsEmpty, 'TestList: IsEmpty failed');
  Coll.Free;